import Foundation

struct Profile: Decodable {
    let username: String
    let firstName: String
    let lastName: String
    let bio: String
    
    enum CodingKeys: String, CodingKey {
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case bio
    }
}

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

final class ProfileService {
    static let shared = ProfileService()
    private init() {}
    
    private var task: URLSessionTask?
    private let queue = DispatchQueue(label: "com.imagefeed.profileservice", qos: .userInitiated)
    
    func fetchProfile(token: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        assert(Thread.isMainThread)
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            if self.task?.state == .cancelled {
                print("[ProfileService] fetchProfile: Task was cancelled")
                return
            }
            
            self.task?.cancel()
            
            do {
                let request = try self.makeRequest(token: token)
                let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("[ProfileService] fetchProfile: NetworkError - \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                        return
                    }
                    
                    if let response = response as? HTTPURLResponse {
                        if response.statusCode < 200 || response.statusCode >= 300 {
                            print("[ProfileService] fetchProfile: HTTPError - status code: \(response.statusCode)")
                            DispatchQueue.main.async {
                                completion(.failure(NetworkError.httpStatusCode(response.statusCode)))
                            }
                            return
                        }
                    }
                    
                    guard let data = data else {
                        print("[ProfileService] fetchProfile: DataError - no data received")
                        DispatchQueue.main.async {
                            completion(.failure(NetworkError.urlRequestError(URLError(.badServerResponse))))
                        }
                        return
                    }
                    
                    do {
                        let decoder = JSONDecoder()
                        let profile = try decoder.decode(Profile.self, from: data)
                        DispatchQueue.main.async {
                            completion(.success(profile))
                        }
                    } catch {
                        print("[ProfileService] fetchProfile: DecodingError - \(error.localizedDescription), data: \(String(data: data, encoding: .utf8) ?? "unable to convert data to string")")
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                }
                self.task = task
                task.resume()
            } catch {
                print("[ProfileService] fetchProfile: RequestError - \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func makeRequest(token: String) throws -> URLRequest {
        guard let baseURL = URL(string: "https://api.unsplash.com/me") else {
            print("[ProfileService] makeRequest: InvalidBaseURL - failed to create URL")
            throw NetworkError.invalidBaseURL
        }
        
        var request = URLRequest(url: baseURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
} 