import UIKit

// MARK: - ImagesListCell
/// Ячейка списка изображений
final class ImagesListCell: UITableViewCell {
    static let reuseIdentifier = "ImagesListCell"
    @IBOutlet var cellImage: UIImageView?
    @IBOutlet var likeButton: UIButton?
    @IBOutlet var dateLabel: UILabel?

    func setIsLiked(_ isLiked: Bool) {
        let likeImage = isLiked ? UIImage(named: "like_button_on") : UIImage(named: "like_button_off")
        likeButton?.setImage(likeImage, for: .normal)
    }
}
