import Foundation

/// Константы приложения
enum Constants {
    /// API константы для работы с Unsplash
    enum API {
        static let defaultBaseURL = URL(string: "https://api.unsplash.com")!
        static let accessScope = "public+read_user+write_likes"
        static let redirectURI = "<ваш Redirect URI>"
        static let secretKey = "<ваш Secret Key>"
        static let accessKey = "<ваш Access Key>"
    }
}
