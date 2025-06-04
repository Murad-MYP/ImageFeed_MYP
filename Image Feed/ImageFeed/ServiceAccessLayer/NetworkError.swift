import Foundation

enum NetworkError: Error {
    case httpStatusCode(Int)
    case urlRequestError(Error)
    case invalidBaseURL
    case invalidURLComponents
    case invalidURL
    
    var localizedDescription: String {
        switch self {
        case .httpStatusCode(let code):
            return "HTTP ошибка: \(code)"
        case .urlRequestError(let error):
            return "Ошибка запроса: \(error.localizedDescription)"
        case .invalidBaseURL:
            return "Некорректный базовый URL"
        case .invalidURLComponents:
            return "Некорректные компоненты URL"
        case .invalidURL:
            return "Некорректный URL"
        }
    }
} 