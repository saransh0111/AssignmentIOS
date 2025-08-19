import Foundation

public enum NetworkError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case invalidStatus(Int)
    case decodingFailed(Error)
    case unauthorized
    case serverError(Int)
    case unknown
}

extension NetworkError {
    public var message: String {
        switch self {
        case .invalidURL:
            return "❌ Invalid URL. Please contact support."

        case .requestFailed(let error):
            return "📡 Request failed due to a network issue: \(error.localizedDescription)"

        case .invalidResponse:
            return "🚫 Received an invalid response from the server."

        case .invalidStatus(let code):
            return "⚠️ Received unexpected status code: \(code)"

        case .decodingFailed(let error):
            return "🧩 Failed to decode server response: \(error.localizedDescription)"

        case .unauthorized:
            return "🔒 You are not authorized. Please login again."

        case .serverError(let code):
            return "💥 Server encountered an error. Code: \(code). Please try again later."

        case .unknown:
            return "❓ An unknown error occurred. Please check your connection or try again later."
        }
    }
}
