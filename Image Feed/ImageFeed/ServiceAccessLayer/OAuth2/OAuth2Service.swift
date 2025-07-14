import Foundation

// MARK: - OAuthTokenResponseBody
/// Модель ответа с OAuth-токеном
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

// MARK: - OAuth2Service
/// Сервис для работы с OAuth2 авторизацией (Singleton)
final class OAuth2Service {
    static let shared = OAuth2Service()
    private init() {}

    private var task: URLSessionTask?
    private var lastCode: String?
    private let lock = NSLock()
    private var isRequestInProgress = false

    /// Получить OAuth-токен по коду авторизации
    func fetchOAuthToken(code: String, completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread)

        guard !code.isEmpty else {
            print("[OAuth2Service] fetchOAuthToken: InvalidInput - пустой код авторизации")
            completion(.failure(NetworkError.invalidURL))
            return
        }

        lock.lock()
        defer { lock.unlock() }

        if isRequestInProgress && lastCode == code {
            print("[OAuth2Service] fetchOAuthToken: DuplicateRequest - дублирующийся запрос с кодом: \(code)")
            return
        }

        if isRequestInProgress && lastCode != code {
            task?.cancel()
            print("[OAuth2Service] fetchOAuthToken: CancellingPrevious - отменяем предыдущий запрос")
        }

        isRequestInProgress = true
        lastCode = code

        do {
            let request = try makeRequest(with: code)
            let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                guard let self = self else {
                    print("[OAuth2Service] fetchOAuthToken: SelfDeallocated")
                    return
                }

                self.lock.lock()
                self.isRequestInProgress = false
                self.lock.unlock()

                if let error = error as NSError?, error.code == NSURLErrorCancelled {
                    print("[OAuth2Service] fetchOAuthToken: TaskCancelled")
                    return
                }

                if let error = error {
                    print("[OAuth2Service] fetchOAuthToken: NetworkError - \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    print("[OAuth2Service] fetchOAuthToken: InvalidResponse")
                    DispatchQueue.main.async {
                        completion(.failure(NetworkError.urlRequestError(URLError(.badServerResponse))))
                    }
                    return
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    print("[OAuth2Service] fetchOAuthToken: HTTPError - статус: \(httpResponse.statusCode)")
                    DispatchQueue.main.async {
                        completion(.failure(NetworkError.httpStatusCode(httpResponse.statusCode)))
                    }
                    return
                }

                guard let data = data else {
                    print("[OAuth2Service] fetchOAuthToken: DataMissing")
                    DispatchQueue.main.async {
                        completion(.failure(NetworkError.urlRequestError(URLError(.badServerResponse))))
                    }
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    let tokenResponse = try decoder.decode(OAuthTokenResponseBody.self, from: data)
                    DispatchQueue.main.async {
                        completion(.success(tokenResponse.accessToken))
                    }
                } catch {
                    let jsonString = String(data: data, encoding: .utf8) ?? "<невалидные данные>"
                    print("[OAuth2Service] fetchOAuthToken: DecodingError - \(error.localizedDescription)\nJSON: \(jsonString)")
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }

            self.task = task
            task.resume()
        } catch {
            isRequestInProgress = false
            print("[OAuth2Service] fetchOAuthToken: RequestBuildFailed - \(error.localizedDescription)")
            DispatchQueue.main.async {
                completion(.failure(error))
            }
        }
    }

    /// Сформировать URLRequest для получения токена
    private func makeRequest(with code: String) throws -> URLRequest {
        guard let baseURL = URL(string: "https://unsplash.com/oauth/token") else {
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
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        return request
    }
}
