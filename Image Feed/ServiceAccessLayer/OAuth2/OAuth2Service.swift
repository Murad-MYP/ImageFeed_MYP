import Foundation

struct OAuthTokenResponseBody: Decodable {
    let accessToken: String
    let tokenType: String
    let scope: String
    let createdAt: Int
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case scope
        case createdAt = "created_at"
    }
}

final class OAuth2Service {
    static let shared = OAuth2Service()
    private init() {}
    
    private var task: URLSessionTask?
    private var lastCode: String?
    private let queue = DispatchQueue(label: "com.imagefeed.oauth2service", qos: .userInitiated)
    
    func fetchOAuthToken(code: String, completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread)
        
        guard !code.isEmpty else {
            print("[OAuth2Service] fetchOAuthToken: InvalidInput - пустой код авторизации")
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        queue.async { [weak self] in
            guard let self = self else {
                print("[OAuth2Service] fetchOAuthToken: SelfError - self был освобожден")
                return
            }
            
            if self.lastCode == code {
                print("[OAuth2Service] fetchOAuthToken: DuplicateRequest - дублирующийся запрос с кодом: \(code)")
                return
            }
            
            self.task?.cancel()
            self.lastCode = code
            
            do {
                let request = try self.makeRequest(code: code)
                let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                    guard let self = self else {
                        print("[OAuth2Service] fetchOAuthToken: SelfError - self был освобожден в completion")
                        return
                    }
                    
                    if self.task?.state == .canceling {
                        print("[OAuth2Service] fetchOAuthToken: TaskCancelled - задача была отменена")
                        return
                    }
                    
                    if let error = error {
                        print("[OAuth2Service] fetchOAuthToken: NetworkError - \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                        return
                    }
                    
                    if let response = response as? HTTPURLResponse {
                        if response.statusCode < 200 || response.statusCode >= 300 {
                            print("[OAuth2Service] fetchOAuthToken: HTTPError - код статуса: \(response.statusCode)")
                            DispatchQueue.main.async {
                                completion(.failure(NetworkError.httpStatusCode(response.statusCode)))
                            }
                            return
                        }
                    }
                    
                    guard let data = data else {
                        print("[OAuth2Service] fetchOAuthToken: DataError - данные не получены")
                        DispatchQueue.main.async {
                            completion(.failure(NetworkError.urlRequestError(URLError(.badServerResponse))))
                        }
                        return
                    }
                    
                    do {
                        let decoder = JSONDecoder()
                        let responseBody = try decoder.decode(OAuthTokenResponseBody.self, from: data)
                        DispatchQueue.main.async {
                            completion(.success(responseBody.accessToken))
                        }
                    } catch {
                        print("[OAuth2Service] fetchOAuthToken: DecodingError - \(error.localizedDescription), данные: \(String(data: data, encoding: .utf8) ?? "невозможно преобразовать данные в строку")")
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                }
                self.task = task
                task.resume()
            } catch {
                print("[OAuth2Service] fetchOAuthToken: RequestError - \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func makeRequest(code: String) throws -> URLRequest {
        guard let baseURL = URL(string: "https://unsplash.com/oauth/token") else {
            print("[OAuth2Service] makeRequest: InvalidBaseURL - не удалось создать URL")
            throw NetworkError.invalidBaseURL
        }
        
        var components = URLComponents()
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.path = baseURL.path
        components.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.API.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.API.secretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.API.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ]
        
        guard let url = components.url else {
            print("[OAuth2Service] makeRequest: InvalidURL - не удалось создать URL из компонентов")
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        return request
    }
} 