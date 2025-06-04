import UIKit
import SwiftKeychainWrapper

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
    private let oauth2TokenStorage = OAuth2TokenStorage.shared
    private let oauth2Service = OAuth2Service.shared
    private let profileService = ProfileService.shared
    private let profileImageService = ProfileImageService.shared
    
    private var logoImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkAuthStatus()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(named: "YP Black")
        
        logoImageView = UIImageView()
        logoImageView.image = UIImage(named: "logo")
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoImageView)
        
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func checkAuthStatus() {
        if oauth2TokenStorage.token != nil {
            switchToTabBarController()
        } else {
            presentAuthViewController()
        }
    }
    
    private func switchToTabBarController() {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        let tabBarController = storyboard.instantiateViewController(withIdentifier: "TabBarViewController")
        
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first else { return }
        
        window.rootViewController = tabBarController
    }
    
    private func presentAuthViewController() {
        let authViewController = AuthViewController()
        authViewController.delegate = self
        authViewController.modalPresentationStyle = .fullScreen
        present(authViewController, animated: true)
    }
}

extension SplashViewController: AuthViewControllerDelegate {
    func authViewController(_ vc: AuthViewController, didAuthenticateWithCode code: String) {
        dismiss(animated: true) { [weak self] in
            self?.fetchOAuthToken(code)
        }
    }
    
    private func fetchOAuthToken(_ code: String) {
        UIBlockingProgressHUD.show()
        oauth2Service.fetchOAuthToken(code: code) { [weak self] result in
            UIBlockingProgressHUD.dismiss()
            guard let self = self else { return }
            
            switch result {
            case .success:
                self.switchToTabBarController()
            case .failure(let error):
                self.showAuthError(error)
            }
        }
    }
    
    private func showAuthError(_ error: Error) {
        let alert = UIAlertController(
            title: "Что-то пошло не так(",
            message: "Не удалось войти в систему",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "ОК", style: .default))
        present(alert, animated: true)
    }
}
