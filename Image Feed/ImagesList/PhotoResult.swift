import Foundation

struct PhotoResult: Decodable {
    let id: String
    let createdAt: String
    let urls: UrlsResult
    let likedByUser: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case urls
        case likedByUser = "liked_by_user"
    }
}

struct UrlsResult: Decodable {
    let small: String
    let thumb: String
    let regular: String
    let full: String
} 