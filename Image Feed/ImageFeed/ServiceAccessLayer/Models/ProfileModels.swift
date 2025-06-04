import Foundation

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

struct ProfileImage: Decodable {
    let profileImage: ProfileImageURLs
    
    enum CodingKeys: String, CodingKey {
        case profileImage = "profile_image"
    }
}

struct ProfileImageURLs: Decodable {
    let small: String
    let medium: String
    let large: String
} 