import UIKit

final class TabBarController: UITabBarController {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupViewControllers()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
    }
    
    private func setupViewControllers() {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        
        // Images List
        let imagesListViewController = storyboard.instantiateViewController(withIdentifier: "ImagesListViewController")
        imagesListViewController.tabBarItem = UITabBarItem(
            title: "",
            image: UIImage(named: "tab_editorial_active"),
            selectedImage: nil
        )
        
        // Profile
        let profileViewController = storyboard.instantiateViewController(withIdentifier: "ProfileViewController")
        profileViewController.tabBarItem = UITabBarItem(
            title: "",
            image: UIImage(named: "tab_profile_active"),
            selectedImage: nil
        )
        
        viewControllers = [imagesListViewController, profileViewController]
        
        // Настройка внешнего вида
        tabBar.backgroundColor = UIColor(named: "YP Black")
        tabBar.barTintColor = UIColor(named: "YP Black")
        tabBar.tintColor = UIColor(named: "YP White")
    }
} 