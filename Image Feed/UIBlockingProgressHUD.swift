import UIKit

final class UIBlockingProgressHUD {
    private static var window: UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
    
    private static var activityIndicator: UIActivityIndicatorView?
    private static let lock = NSLock()
    private static var isShowing = false
    
    static func show() {
        lock.lock()
        defer { lock.unlock() }
        
        guard !isShowing else {
            print("[UIBlockingProgressHUD] show: AlreadyShowing - индикатор уже отображается")
            return
        }
        
        DispatchQueue.main.async {
            guard let window = window else {
                print("[UIBlockingProgressHUD] show: NoWindow - окно не найдено")
                return
            }
            
            let activityIndicator = UIActivityIndicatorView(style: .large)
            activityIndicator.color = .white
            activityIndicator.center = window.center
            activityIndicator.startAnimating()
            
            window.addSubview(activityIndicator)
            window.isUserInteractionEnabled = false
            self.activityIndicator = activityIndicator
            isShowing = true
        }
    }
    
    static func dismiss() {
        lock.lock()
        defer { lock.unlock() }
        
        guard isShowing else {
            print("[UIBlockingProgressHUD] dismiss: NotShowing - индикатор не отображается")
            return
        }
        
        DispatchQueue.main.async {
            guard let window = window else {
                print("[UIBlockingProgressHUD] dismiss: NoWindow - окно не найдено")
                return
            }
            
            activityIndicator?.stopAnimating()
            activityIndicator?.removeFromSuperview()
            activityIndicator = nil
            window.isUserInteractionEnabled = true
            isShowing = false
        }
    }
} 