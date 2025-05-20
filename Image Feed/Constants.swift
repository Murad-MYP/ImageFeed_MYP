import Foundation

/// Константы приложения
enum Constants {
    /// API константы для работы с Unsplash
    enum API {
        static let defaultBaseURL = URL(string: "https://api.unsplash.com")!
        static let accessScope = "public+read_user+write_likes"
        static let redirectURI = "urn:ietf:wg:oauth:2.0:oob"
        static let secretKey = "_dG6ylkUDpwmL0mK_b4Ym-fUXm3GFE1l5S0YU1XkfIA"
        static let accessKey = "tnZWP4_QOjUChKVUe-Sp4dAUJUXTv2oFisJDfZ39OD8"
    }
}
