import Foundation

final class ProfileService {
    static let shared = ProfileService()
    private init() {}
    
    private var task: URLSessionTask?
    private let lock = NSLock()
    
    func fetchProfile(token: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        assert(Thread.isMainThread)
        
        lock.lock()
        defer { lock.unlock() }
        
        task?.cancel()
        
        do {
            let request = try makeRequest(token: token)
            let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                guard let self = self else {
                    print("[ProfileService] fetchProfile: SelfError - self был освобожден")
                    return
                }
                
                if let error = error as NSError?, error.code == NSURLErrorCancelled {
                    print("[ProfileService] fetchProfile: TaskCancelled - задача была отменена")
                    return
                }
                
                if let error = error {
                    print("[ProfileService] fetchProfile: NetworkError - \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                
                guard let response = response as? HTTPURLResponse else {
                    print("[ProfileService] fetchProfile: InvalidResponse - невалидный ответ")
                    DispatchQueue.main.async {
                        completion(.failure(NetworkError.urlRequestError(URLError(.badServerResponse))))
                    }
                    return
                }
                
                if response.statusCode < 200 || response.statusCode >= 300 {
                    print("[ProfileService] fetchProfile: HTTPError - код статуса: \(response.statusCode)")
                    DispatchQueue.main.async {
                        completion(.failure(NetworkError.httpStatusCode(response.statusCode)))
                    }
                    return
                }
                
                guard let data = data else {
                    print("[ProfileService] fetchProfile: DataError - данные не получены")
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
                    print("[ProfileService] fetchProfile: DecodingError - \(error.localizedDescription), данные: \(String(data: data, encoding: .utf8) ?? "невозможно преобразовать данные в строку")")
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
    
    private func makeRequest(token: String) throws -> URLRequest {
        guard let baseURL = URL(string: "https://api.unsplash.com/me") else {
            print("[ProfileService] makeRequest: InvalidBaseURL - не удалось создать URL")
            throw NetworkError.invalidBaseURL
        }
        
        var request = URLRequest(url: baseURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
} 