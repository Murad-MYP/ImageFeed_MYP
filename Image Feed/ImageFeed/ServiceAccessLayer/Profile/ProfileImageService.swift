import Foundation

struct UserResult: Decodable {
    let profileImage: ProfileImageURL
    
    enum CodingKeys: String, CodingKey {
        case profileImage = "profile_image"
    }
}

struct ProfileImageURL: Decodable {
    let small: String
    let medium: String
    let large: String
}

final class ProfileImageService {
    static let shared = ProfileImageService()
    static let didChangeNotification = Notification.Name("ProfileImageProviderDidChange")
    
    private init() {}
    
    private var task: URLSessionTask?
    private let lock = NSLock()
    private(set) var avatarURL: String?
    
    func fetchProfileImageURL(username: String, completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread)
        
        lock.lock()
        defer { lock.unlock() }
        
        task?.cancel()
        
        do {
            let request = try makeRequest(username: username)
            let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                guard let self = self else {
                    print("[ProfileImageService] fetchProfileImageURL: SelfError - self был освобожден")
                    return
                }
                
                if let error = error as NSError?, error.code == NSURLErrorCancelled {
                    print("[ProfileImageService] fetchProfileImageURL: TaskCancelled - задача была отменена")
                    return
                }
                
                if let error = error {
                    print("[ProfileImageService] fetchProfileImageURL: NetworkError - \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                
                guard let response = response as? HTTPURLResponse else {
                    print("[ProfileImageService] fetchProfileImageURL: InvalidResponse - невалидный ответ")
                    DispatchQueue.main.async {
                        completion(.failure(NetworkError.urlRequestError(URLError(.badServerResponse))))
                    }
                    return
                }
                
                if response.statusCode < 200 || response.statusCode >= 300 {
                    print("[ProfileImageService] fetchProfileImageURL: HTTPError - код статуса: \(response.statusCode)")
                    DispatchQueue.main.async {
                        completion(.failure(NetworkError.httpStatusCode(response.statusCode)))
                    }
                    return
                }
                
                guard let data = data else {
                    print("[ProfileImageService] fetchProfileImageURL: DataError - данные не получены")
                    DispatchQueue.main.async {
                        completion(.failure(NetworkError.urlRequestError(URLError(.badServerResponse))))
                    }
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let userResult = try decoder.decode(UserResult.self, from: data)
                    let imageURL = userResult.profileImage.large
                    
                    DispatchQueue.main.async {
                        self.avatarURL = imageURL
                        completion(.success(imageURL))
                        NotificationCenter.default.post(
                            name: ProfileImageService.didChangeNotification,
                            object: self,
                            userInfo: ["URL": imageURL]
                        )
                    }
                } catch {
                    print("[ProfileImageService] fetchProfileImageURL: DecodingError - \(error.localizedDescription), данные: \(String(data: data, encoding: .utf8) ?? "невозможно преобразовать данные в строку")")
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
            self.task = task
            task.resume()
        } catch {
            print("[ProfileImageService] fetchProfileImageURL: RequestError - \(error.localizedDescription)")
            DispatchQueue.main.async {
                completion(.failure(error))
            }
        }
    }
    
    private func makeRequest(username: String) throws -> URLRequest {
        guard let baseURL = URL(string: "https://api.unsplash.com/users/\(username)") else {
            print("[ProfileImageService] makeRequest: InvalidBaseURL - не удалось создать URL")
            throw NetworkError.invalidBaseURL
        }
        
        guard let token = OAuth2TokenStorage.shared.token else {
            print("[ProfileImageService] makeRequest: NoToken - токен не найден")
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: baseURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
} 