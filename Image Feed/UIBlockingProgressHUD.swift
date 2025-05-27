import UIKit

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