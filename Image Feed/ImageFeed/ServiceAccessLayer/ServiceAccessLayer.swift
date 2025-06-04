import Foundation

final class ServiceAccessLayer {
    static let shared = ServiceAccessLayer()
    
    let profileService: ProfileService
    let profileImageService: ProfileImageService
    let oauth2Service: OAuth2Service
    let oauth2TokenStorage: OAuth2TokenStorage
    
    init(profileService: ProfileService = ProfileService.shared,
         profileImageService: ProfileImageService = ProfileImageService.shared,
         oauth2Service: OAuth2Service = OAuth2Service.shared,
         oauth2TokenStorage: OAuth2TokenStorage = OAuth2TokenStorage.shared) {
        self.profileService = profileService
        self.profileImageService = profileImageService
        self.oauth2Service = oauth2Service
        self.oauth2TokenStorage = oauth2TokenStorage
    }
} 