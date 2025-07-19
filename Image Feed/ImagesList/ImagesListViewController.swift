import UIKit

// MARK: - ImagesListViewController
/// Контроллер списка изображений
final class ImagesListViewController: UIViewController {
    private let showSingleImageSegueIdentifier = "ShowSingleImage"

    @IBOutlet private var tableView: UITableView?

    private var photos: [Photo] = []
    private let imagesListService = ImagesListService.shared
    private var imagesListServiceObserver: NSObjectProtocol?

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView?.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        tableView?.delegate = self
        tableView?.dataSource = self
        imagesListServiceObserver = NotificationCenter.default.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateTableViewAnimated()
        }
        imagesListService.fetchPhotosNextPage()
    }

    deinit {
        if let observer = imagesListServiceObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func updateTableViewAnimated() {
        let oldCount = photos.count
        photos = imagesListService.photos
        guard let tableView = tableView else { return }
        if oldCount != photos.count {
            let newIndexPaths = (oldCount..<photos.count).map { IndexPath(row: $0, section: 0) }
            tableView.performBatchUpdates({
                tableView.insertRows(at: newIndexPaths, with: .automatic)
            }, completion: nil)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showSingleImageSegueIdentifier {
            guard let viewController = segue.destination as? SingleImageViewController,
                  let indexPath = sender as? IndexPath else {
                print("[ImagesListViewController] Error: Failed to prepare for segue")
                return
            }
            let photo = photos[indexPath.row]
            viewController.fullImageURL = photo.fullImageURL
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
}

// MARK: - UITableViewDataSource
extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath)

        guard let imageListCell = cell as? ImagesListCell else {
            return UITableViewCell()
        }

        configCell(for: imageListCell, with: indexPath)

        // Подгружаем следующую страницу, если дошли до конца
        if indexPath.row == photos.count - 1 {
            imagesListService.fetchPhotosNextPage()
        }

        return imageListCell
    }
}

// MARK: - Cell Configuration
extension ImagesListViewController {
    /// Настройка ячейки списка изображений
    func configCell(for cell: ImagesListCell, with indexPath: IndexPath) {
        let photo = photos[indexPath.row]
        cell.cellImage?.image = UIImage(named: photo.imageName) // или загрузка по URL
        if let date = photo.createdAt {
            cell.dateLabel?.text = dateFormatter.string(from: date)
        } else {
            cell.dateLabel?.text = ""
        }
        cell.setIsLiked(photo.isLiked)
        cell.likeButton?.removeTarget(nil, action: nil, for: .allEvents)
        cell.likeButton?.addTarget(self, action: #selector(didTapLikeButton(_:)), for: .touchUpInside)
    }
}

// MARK: - UITableViewDelegate
extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: showSingleImageSegueIdentifier, sender: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let photo = photos[indexPath.row]
        guard let image = UIImage(named: photo.imageName) else {
            return 0
        }
        let imageInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let imageViewWidth = tableView.bounds.width - imageInsets.left - imageInsets.right
        let imageWidth = image.size.width
        let scale = imageViewWidth / imageWidth
        let cellHeight = image.size.height * scale + imageInsets.top + imageInsets.bottom
        return cellHeight
    }
}

extension ImagesListViewController {
    @objc func didTapLikeButton(_ sender: UIButton) {
        guard let tableView = tableView,
              let indexPath = tableView.indexPathForRow(at: sender.convert(sender.bounds.origin, to: tableView)),
              indexPath.row < photos.count else { return }
        // Блокируем UI
        UIBlockingProgressHUD.show()
        // Мок-сервис смены лайка (заменить на реальный сетевой вызов)
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.photos[indexPath.row].isLiked.toggle()
                if let cell = tableView.cellForRow(at: indexPath) as? ImagesListCell {
                    cell.setIsLiked(self.photos[indexPath.row].isLiked)
                }
                UIBlockingProgressHUD.dismiss()
            }
        }
    }
}
