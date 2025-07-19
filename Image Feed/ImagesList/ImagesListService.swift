import Foundation

final class ImagesListService {
    static let shared = ImagesListService()
    static let didChangeNotification = Notification.Name("ImagesListServiceDidChange")

    private(set) var photos: [Photo] = []
    private var lastLoadedPage = 0
    private var isLoading = false
    private let lock = NSLock()

    private init() {}

    func fetchPhotosNextPage() {
        lock.lock()
        defer { lock.unlock() }
        guard !isLoading else { return }
        isLoading = true
        let nextPage = lastLoadedPage + 1
        // Здесь должен быть реальный сетевой запрос. Для примера — мок:
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            do {
                let newPhotoResults: [PhotoResult] = self.mockPhotoResults(page: nextPage)
                let dateFormatter = ISO8601DateFormatter()
                let newPhotos: [Photo] = newPhotoResults.map { result in
                    let date = dateFormatter.date(from: result.createdAt)
                    if date == nil {
                        print("[ImagesListService.fetchPhotosNextPage]: [date parse error] id=\(result.id) createdAt=\(result.createdAt)")
                    }
                    return Photo(
                        id: result.id,
                        imageName: result.urls.small, // или другой url
                        createdAt: date,
                        isLiked: result.likedByUser,
                        fullImageURL: result.urls.full
                    )
                }
                DispatchQueue.main.async {
                    self.lock.lock(); defer { self.lock.unlock() }
                    self.photos.append(contentsOf: newPhotos)
                    self.lastLoadedPage = nextPage
                    self.isLoading = false
                    NotificationCenter.default.post(name: ImagesListService.didChangeNotification, object: self)
                }
            } catch {
                print("[ImagesListService.fetchPhotosNextPage]: [decoding error] page=\(nextPage) error=\(error)")
            }
        }
    }

    // Мок-данные для примера
    private func mockPhotoResults(page: Int) -> [PhotoResult] {
        return (0..<10).map { i in
            PhotoResult(
                id: "photo_\(page)_\(i)",
                createdAt: "2016-05-03T11:00:28-04:00",
                urls: UrlsResult(small: "\(i)", thumb: "", regular: "", full: "https://example.com/full_\(i).jpg"),
                likedByUser: i % 2 == 0
            )
        }
    }
} 