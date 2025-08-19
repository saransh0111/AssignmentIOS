import Foundation

// MARK: - Configuration

private struct NetworkConfig {
    // ✅ Always keep slash here in baseURL
    // Example: "https://api.mfapi.in/"
    // If some project does NOT need slash, just remove it here.
    static let baseURL = "https://api.mfapi.in/"
    static let timeout: TimeInterval = 30

    static var defaultHeaders: [String: String] {
        var headers = ["Accept": "application/json"]
        if let token = TokenManager.shared.accessToken {
            headers["Authorization"] = "Bearer \(token)"
        }
        return headers
    }
}

// MARK: - NetworkManager
final class NetworkManager {
    public static let shared = NetworkManager()
    private init() {}

    public func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let urlRequest = try makeRequest(from: endpoint)
        
        // 🔍 Log request
        logRequest(urlRequest, body: endpoint.body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: urlRequest)
        } catch {
            print("❌ Request failed: \(error.localizedDescription)")
            throw NetworkError.requestFailed(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid HTTP response")
            throw NetworkError.invalidStatus(-1)
        }

        print("⬅️ Status Code: \(httpResponse.statusCode)")

        guard (200..<300).contains(httpResponse.statusCode) else {
            if let errorBody = String(data: data, encoding: .utf8) {
                print("❌ Server error body: \(errorBody)")
            }
            throw NetworkError.invalidStatus(httpResponse.statusCode)
        }

        // Decode response
        do {
            let decoded = try JSONDecoder().decode(T.self, from: data)
            print("✅ Decoded response: \(decoded)")
            return decoded
        } catch {
            print("❌ JSON decode failed: \(error.localizedDescription)")
            if let raw = String(data: data, encoding: .utf8) {
                print("🔍 Raw response: \(raw)")
            }
            throw NetworkError.decodingFailed(error)
        }
    }

    // MARK: - Helpers

    private func makeRequest(from endpoint: Endpoint) throws -> URLRequest {
        // ✅ Ensure we join baseURL + path cleanly
        let fullURLString = NetworkConfig.baseURL + endpoint.path

        guard var components = URLComponents(string: fullURLString) else {
            throw NetworkError.invalidURL
        }

        if let queryParams = endpoint.queryParameters {
            components.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url, timeoutInterval: NetworkConfig.timeout)
        request.httpMethod = endpoint.method.rawValue

        // Headers
        NetworkConfig.defaultHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        endpoint.headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        if let contentType = endpoint.contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }

        // Body
        request.httpBody = endpoint.body

        return request
    }

    private func logRequest(_ request: URLRequest, body: Data?) {
        print("📤 Request Started")
        print("➡️ URL: \(request.url?.absoluteString ?? "nil")")
        print("➡️ Method: \(request.httpMethod ?? "nil")")
        print("➡️ Headers: \(request.allHTTPHeaderFields ?? [:])")

        if let body = body,
           let bodyString = String(data: body, encoding: .utf8) {
            print("➡️ Body: \(bodyString)")
        }
    }
}
