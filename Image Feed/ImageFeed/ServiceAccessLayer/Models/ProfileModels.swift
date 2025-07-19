import Foundation

// MARK: - Profile
/// Модель профиля пользователя
struct Profile: Decodable {
    let username: String
    let firstName: String
    let lastName: String
    let bio: String?
    
    enum CodingKeys: String, CodingKey {
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case bio
    }
}

// MARK: - ProfileImage
/// Модель изображения профиля
struct ProfileImage: Decodable {
    let profileImage: ProfileImageURLs
    
    enum CodingKeys: String, CodingKey {
        case profileImage = "profile_image"
    }
}

// MARK: - ProfileImageURLs
/// URL-адреса изображений профиля
struct ProfileImageURLs: Decodable {
    let small: String
    let medium: String
    let large: String
} 