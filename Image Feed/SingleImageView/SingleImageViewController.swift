import UIKit

// MARK: - SingleImageViewController
/// Контроллер для просмотра одного изображения с возможностью масштабирования и шаринга
final class SingleImageViewController: UIViewController {
    var image: UIImage? {
        didSet {
            guard isViewLoaded else { return }
            imageView?.image = image
            if let image = image {
                rescaleAndCenterImageInScrollView(image: image)
            }
        }
    }
    
    var fullImageURL: String?
    
    @IBOutlet weak var scrollView: UIScrollView?
    @IBOutlet private var imageView: UIImageView?

    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView?.minimumZoomScale = 0.1
        scrollView?.maximumZoomScale = 1.25
        if let urlString = fullImageURL, let url = URL(string: urlString) {
            UIBlockingProgressHUD.show()
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.imageView?.image = image
                        self.rescaleAndCenterImageInScrollView(image: image)
                        UIBlockingProgressHUD.dismiss()
                    }
                } else {
                    DispatchQueue.main.async {
                        UIBlockingProgressHUD.dismiss()
                        // Можно показать ошибку
                    }
                }
            }
        } else if let image = image {
            imageView?.image = image
            rescaleAndCenterImageInScrollView(image: image)
        }
    }

    /// Обработка нажатия кнопки "Назад"
    @IBAction private func didTapBackButton() {
        dismiss(animated: true, completion: nil)
    }
    
    /// Обработка нажатия кнопки "Поделиться"
    @IBAction func didTapShareButton(_ sender: UIButton) {
        guard let image = image else { return }
        let share = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        present(share, animated: true, completion: nil)
    }
    
    /// Масштабирование и центрирование изображения в scrollView
    private func rescaleAndCenterImageInScrollView(image: UIImage) {
        let minZoomScale = scrollView?.minimumZoomScale ?? 0.1
        let maxZoomScale = scrollView?.maximumZoomScale ?? 1.25
        view.layoutIfNeeded()
        let visibleRectSize = scrollView?.bounds.size ?? .zero
        let imageSize = image.size
        let hScale = visibleRectSize.width / imageSize.width
        let vScale = visibleRectSize.height / imageSize.height
        let scale = min(maxZoomScale, max(minZoomScale, max(hScale, vScale)))
        scrollView?.setZoomScale(scale, animated: false)
        scrollView?.layoutIfNeeded()
        let newContentSize = scrollView?.contentSize ?? .zero
        let x = (newContentSize.width - visibleRectSize.width) / 2
        let y = (newContentSize.height - visibleRectSize.height) / 2
        scrollView?.setContentOffset(CGPoint(x: x, y: y), animated: false)
    }
}

// MARK: - UIScrollViewDelegate
extension SingleImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
}
