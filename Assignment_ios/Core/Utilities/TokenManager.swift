import Foundation

/// Manages access + refresh tokens in Keychain, and login/profile state in UserDefaults
final class TokenManager {
    static let shared = TokenManager()
    private init() {}

    private let service = Bundle.main.bundleIdentifier ?? "WofaApp"
    private let accessKey = "access_token"
    private let refreshKey = "refresh_token"

    // MARK: - Keychain Token Accessors
    var accessToken: String? {
        guard
            let d = KeychainHelper.standard.read(service: service, account: accessKey),
            let tok = String(data: d, encoding: .utf8)
        else { return nil }
        return tok
    }

    var refreshToken: String? {
        guard
            let d = KeychainHelper.standard.read(service: service, account: refreshKey),
            let tok = String(data: d, encoding: .utf8)
        else { return nil }
        return tok
    }

    func saveTokens(access: String, refresh: String?) {
        KeychainHelper.standard.save(Data(access.utf8), service: service, account: accessKey)
        if let r = refresh {
            KeychainHelper.standard.save(Data(r.utf8), service: service, account: refreshKey)
        }
        UserDefaults.standard.set(true, forKey: "signIn")
    }

    func clearTokens() {
        KeychainHelper.standard.delete(service: service, account: accessKey)
        KeychainHelper.standard.delete(service: service, account: refreshKey)

        UserDefaults.standard.set(false, forKey: "signIn")
        UserDefaults.standard.set(false, forKey: "profileComplete")
        UserDefaults.standard.removeObject(forKey: "userEmail")
    }

    // MARK: - UserDefaults Management
    var isLoggedIn: Bool {
        return UserDefaults.standard.bool(forKey: "signIn")
    }

    var isProfileComplete: Bool {
        return UserDefaults.standard.bool(forKey: "profileComplete")
    }

    func markProfileComplete() {
        UserDefaults.standard.set(true, forKey: "profileComplete")
    }

    func saveUserEmail(_ email: String) {
        UserDefaults.standard.set(email, forKey: "userEmail")
    }

    var userEmail: String? {
        return UserDefaults.standard.string(forKey: "userEmail")
    }
}
