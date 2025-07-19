import Foundation

struct Photo {
    let id: String
    let imageName: String // или url: String, если фото по сети
    let createdAt: Date?
    let isLiked: Bool
    let fullImageURL: String
} 