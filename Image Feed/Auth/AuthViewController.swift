import UIKit

protocol AuthViewControllerDelegate: AnyObject {
    func authViewController(_ vc: AuthViewController, didAuthenticateWithCode code: String)
}

final class AuthViewController: UIViewController {
    weak var delegate: AuthViewControllerDelegate?
    
    private var logoImageView: UIImageView!
    private var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(named: "YP Black")
        
        // Logo
        logoImageView = UIImageView()
        logoImageView.image = UIImage(named: "auth_screen_logo")
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoImageView)
        
        // Login button
        loginButton = UIButton(type: .system)
        loginButton.setTitle("Войти", for: .normal)
        loginButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        loginButton.setTitleColor(.black, for: .normal)
        loginButton.backgroundColor = .white
        loginButton.layer.cornerRadius = 16
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        view.addSubview(loginButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            loginButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -90),
            loginButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
    
    @objc private func loginButtonTapped() {
        let webViewViewController = WebViewViewController()
        webViewViewController.delegate = self
        webViewViewController.modalPresentationStyle = .fullScreen
        present(webViewViewController, animated: true)
    }
    
    func showNetworkError() {
        let alert = UIAlertController(
            title: "Что-то пошло не так(",
            message: "Не удалось войти в систему",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }
}

extension AuthViewController: WebViewViewControllerDelegate {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
        vc.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.delegate?.authViewController(self, didAuthenticateWithCode: code)
        }
    }

    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        vc.dismiss(animated: true)
    }
}
