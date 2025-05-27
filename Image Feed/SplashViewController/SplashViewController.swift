import UIKit

struct Profile: Decodable {
    let username: String
    let firstName: String
    let lastName: String
    let bio: String
    
    enum CodingKeys: String, CodingKey {
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case bio
    }
}

enum NetworkError: Error {
    case httpStatusCode(Int)
    case urlRequestError(Error)
    case invalidBaseURL
    case invalidURLComponents
    case invalidURL
    
    var localizedDescription: String {
        switch self {
        case .httpStatusCode(let code):
            return "HTTP ошибка: \(code)"
        case .urlRequestError(let error):
            return "Ошибка запроса: \(error.localizedDescription)"
        case .invalidBaseURL:
            return "Некорректный базовый URL"
        case .invalidURLComponents:
            return "Некорректные компоненты URL"    
        case .invalidURL:
            return "Некорректный URL"
        }
    }
}

final class ProfileService {
    static let shared = ProfileService()
    private init() {}
    
    private var task: URLSessionTask?
    private let queue = DispatchQueue(label: "com.imagefeed.profileservice", qos: .userInitiated)
    
    func fetchProfile(token: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        assert(Thread.isMainThread)
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            self.task?.cancel()
            
            do {
                let request = try self.makeRequest(token: token)
                let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("[ProfileService] fetchProfile: NetworkError - \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                        return
                    }
                    
                    if let response = response as? HTTPURLResponse {
                        if response.statusCode < 200 || response.statusCode >= 300 {
                            print("[ProfileService] fetchProfile: HTTPError - status code: \(response.statusCode)")
                            DispatchQueue.main.async {
                                completion(.failure(NetworkError.httpStatusCode(response.statusCode)))
                            }
                            return
                        }
                    }
                    
                    guard let data = data else {
                        print("[ProfileService] fetchProfile: DataError - no data received")
                        DispatchQueue.main.async {
                            completion(.failure(NetworkError.urlRequestError(URLError(.badServerResponse))))
                        }
                        return
                    }
                    
                    do {
                        let decoder = JSONDecoder()
                        let profile = try decoder.decode(Profile.self, from: data)
                        DispatchQueue.main.async {
                            completion(.success(profile))
                        }
                    } catch {
                        print("[ProfileService] fetchProfile: DecodingError - \(error.localizedDescription), data: \(String(data: data, encoding: .utf8) ?? "unable to convert data to string")")
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                }
                self.task = task
                task.resume()
            } catch {
                print("[ProfileService] fetchProfile: RequestError - \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func makeRequest(token: String) throws -> URLRequest {
        guard let baseURL = URL(string: "https://api.unsplash.com/me") else {
            print("[ProfileService] makeRequest: InvalidBaseURL - failed to create URL")
            throw NetworkError.invalidBaseURL
        }
        
        var request = URLRequest(url: baseURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}

final class UIBlockingProgressHUD {
    private static var window: UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first
    }
    
    private static var activityIndicator: UIActivityIndicatorView?
    
    static func show() {
        guard let window = window else {
            print("[UIBlockingProgressHUD] show: No window found")
            return
        }
        
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .white
        activityIndicator.center = window.center
        activityIndicator.startAnimating()
        
        window.addSubview(activityIndicator)
        window.isUserInteractionEnabled = false
        self.activityIndicator = activityIndicator
    }
    
    static func dismiss() {
        guard let window = window else {
            print("[UIBlockingProgressHUD] dismiss: No window found")
            return
        }
        
        activityIndicator?.stopAnimating()
        activityIndicator?.removeFromSuperview()
        activityIndicator = nil
        window.isUserInteractionEnabled = true
    }
}

final class SplashViewController: UIViewController {
    private let ShowAuthenticationScreenSegueIdentifier = "ShowAuthenticationScreen"

    private let oauth2Service = OAuth2Service.shared
    private let oauth2TokenStorage = OAuth2TokenStorage.shared
    private let profileService = ProfileService.shared
    
    private var isFetchingToken = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let token = oauth2TokenStorage.token {
            fetchProfile(token: token)
        } else {
            // Show Auth Screen
            performSegue(withIdentifier: ShowAuthenticationScreenSegueIdentifier, sender: nil)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    private func setupUI() {
        view.backgroundColor = .black
    }

    private func switchToTabBarController() {
        guard let window = UIApplication.shared.windows.first else { 
            print("[SplashViewController] switchToTabBarController: InvalidConfiguration - no window found")
            return
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        guard let tabBarController = storyboard.instantiateViewController(withIdentifier: "TabBarViewController") as? UITabBarController else {
            print("[SplashViewController] switchToTabBarController: InvalidConfiguration - failed to create TabBarController")
            return
        }
        window.rootViewController = tabBarController
    }

    private func fetchProfile(token: String) {
        UIBlockingProgressHUD.show()
        profileService.fetchProfile(token: token) { [weak self] result in
            guard let self = self else { return }
            UIBlockingProgressHUD.dismiss()
            
            switch result {
            case .success:
                self.switchToTabBarController()
            case .failure(let error):
                print("[SplashViewController] fetchProfile: ProfileError - \(error.localizedDescription)")
                self.showError()
            }
        }
    }
}

extension SplashViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == ShowAuthenticationScreenSegueIdentifier {
            guard
                let navigationController = segue.destination as? UINavigationController,
                let viewController = navigationController.viewControllers.first as? AuthViewController
            else {
                print("[SplashViewController] prepare: InvalidConfiguration - failed to prepare for \(ShowAuthenticationScreenSegueIdentifier)")
                return
            }
            viewController.delegate = self
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
}

extension SplashViewController: AuthViewControllerDelegate {
    func authViewController(_ vc: AuthViewController, didAuthenticateWithCode code: String) {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            if !self.isFetchingToken {
                self.isFetchingToken = true
                UIBlockingProgressHUD.show()
                self.fetchOAuthToken(code)
            }
        }
    }

    private func fetchOAuthToken(_ code: String) {
        oauth2Service.fetchOAuthToken(code: code) { [weak self] result in
            guard let self = self else { return }
            self.isFetchingToken = false
            UIBlockingProgressHUD.dismiss()
            
            switch result {
            case .success(let token):
                self.oauth2TokenStorage.token = token
                self.fetchProfile(token: token)
            case .failure(let error):
                print("[SplashViewController] fetchOAuthToken: OAuthError - \(error.localizedDescription)")
                self.showError()
            }
        }
    }

    private func showError() {
        let alert = UIAlertController(
            title: "Что-то пошло не так(",
            message: "Не удалось войти в систему",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
