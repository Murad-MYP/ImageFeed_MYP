import UIKit
import Kingfisher

// MARK: - ProfileViewController
/// Контроллер профиля пользователя
final class ProfileViewController: UIViewController {
    @IBOutlet private var avatarImageView: UIImageView?
    @IBOutlet private var nameLabel: UILabel?
    @IBOutlet private var loginNameLabel: UILabel?
    @IBOutlet private var descriptionLabel: UILabel?
    @IBOutlet private var logoutButton: UIButton?
    
    private let profileService = ProfileService.shared
    private let oauth2TokenStorage = OAuth2TokenStorage.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateProfile()
    }
    
    /// Обновить данные профиля на экране
    private func updateProfile() {
        guard let token = oauth2TokenStorage.token else { return }
        
        profileService.fetchProfile(token: token) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let profile):
                DispatchQueue.main.async {
                    self.nameLabel?.text = "\(profile.firstName) \(profile.lastName)"
                    self.loginNameLabel?.text = "@\(profile.username)"
                    self.descriptionLabel?.text = profile.bio
                }
            case .failure(let error):
                print("Profile error: \(error)")
            }
        }
    }
    
    /// Обработка нажатия на кнопку выхода
    @IBAction private func didTapLogoutButton() {
        let alert = UIAlertController(
            title: "Выход",
            message: "Вы уверены, что хотите выйти из аккаунта?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Выйти", style: .destructive) { [weak self] _ in
            self?.logout()
        })
        present(alert, animated: true)
    }

    private func logout() {
        // Удаляем токен
        oauth2TokenStorage.token = nil
        // Очищаем куки
        HTTPCookieStorage.shared.removeCookies(since: .distantPast)
        // Переход на SplashViewController
        guard let window = UIApplication.shared.windows.first else { return }
        let splashVC = SplashViewController()
        window.rootViewController = splashVC
        window.makeKeyAndVisible()
    }
}
