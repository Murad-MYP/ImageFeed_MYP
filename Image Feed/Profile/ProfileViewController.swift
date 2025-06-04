import UIKit
import Kingfisher

final class ProfileViewController: UIViewController {
    @IBOutlet private var avatarImageView: UIImageView!
    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var loginNameLabel: UILabel!
    @IBOutlet private var descriptionLabel: UILabel!
    @IBOutlet private var logoutButton: UIButton!
    
    private let profileService = ProfileService.shared
    private let oauth2TokenStorage = OAuth2TokenStorage.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateProfile()
    }
    
    private func updateProfile() {
        guard let token = oauth2TokenStorage.token else { return }
        
        profileService.fetchProfile(token: token) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let profile):
                DispatchQueue.main.async {
                    self.nameLabel.text = "\(profile.firstName) \(profile.lastName)"
                    self.loginNameLabel.text = "@\(profile.username)"
                    self.descriptionLabel.text = profile.bio
                }
            case .failure(let error):
                print("Profile error: \(error)")
            }
        }
    }
    
    @IBAction private func didTapLogoutButton() {
        oauth2TokenStorage.token = nil
    }
}
