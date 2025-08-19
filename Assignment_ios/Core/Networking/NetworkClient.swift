import Foundation

protocol NetworkClientProtocol {
    func request<T: Decodable>(_ request: Endpoint) async throws -> T
}
 final class NetworkClient: NetworkClientProtocol {
    public static let shared = NetworkClient()
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    public func request<T: Decodable>(_ request: Endpoint) async throws -> T {
        return try await performRequest(request, retries: 1)
    }

    private func performRequest<T: Decodable>(_ request: Endpoint, retries: Int) async throws -> T {
        // Build URL
        guard var urlComponents = URLComponents(string: APIConfig.baseURL) else {
            throw NetworkError.invalidURL
        }

        urlComponents.path = request.path
        if let queryParameters = request.queryParameters {
        urlComponents.queryItems = queryParameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        guard let url = urlComponents.url else {
            throw NetworkError.invalidURL
        }

        // Prepare URLRequest
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body

        // Headers from request
        request.headers?.forEach { key, value in
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        // Default headers
        if [.POST, .PUT, .PATCH].contains(request.method),
           urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        // Authorization token (if available)
        if let token = TokenManager.shared.accessToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Debug logging
        #if DEBUG
        print("📤 Request Started")
        print("➡️ URL: \(url)")
        print("➡️ Method: \(request.method.rawValue)")
        print("➡️ Headers: \(urlRequest.allHTTPHeaderFields ?? [:])")
        if let body = request.body,
           let bodyString = String(data: body, encoding: .utf8) {
            print("➡️ Body: \(bodyString)")
        }
        #endif

        // Perform request
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            if retries > 0 {
                return try await performRequest(request, retries: retries - 1)
            }
            throw NetworkError.requestFailed(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        #if DEBUG
        print("⬅️ Status Code: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📩 Raw Response: \(responseString)")
        }
        #endif

        switch httpResponse.statusCode {
        case 200..<300:
            do {
                let decoder = JSONDecoder()
                let decoded = try decoder.decode(T.self, from: data)
                #if DEBUG
                print("✅ Decoded Response: \(decoded)")
                #endif
                return decoded
            } catch {
                #if DEBUG
                print("❌ JSON Decoding failed: \(error.localizedDescription)")
                #endif
                throw NetworkError.decodingFailed(error)
            }

        case 401:
            throw NetworkError.unauthorized

        case 500...599:
            if retries > 0 {
                return try await performRequest(request, retries: retries - 1)
            }
            throw NetworkError.serverError(httpResponse.statusCode)

        default:
            throw NetworkError.invalidStatus(httpResponse.statusCode)
        }
    }
}
