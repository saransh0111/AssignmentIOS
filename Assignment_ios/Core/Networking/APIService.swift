import Foundation

protocol APIServiceProtocol {
    func request<T: Codable>(_ endpoint: Endpoint) async throws -> T
}

final class APIService: APIServiceProtocol {
    static let shared = APIService()
    private init() {}
    
    func request<T: Codable>(_ endpoint: Endpoint) async throws -> T {
        return try await NetworkManager.shared.request(endpoint)
    }
    
}
