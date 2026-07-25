import Foundation
import Security

protocol TokenStore {
    func save(_ token: String)
    func load() -> String?
    func clear()
}

final class KeychainTokenStore: TokenStore {
    private let account = "authToken"

    func save(_ token: String) {
        KeychainStore.save(Data(token.utf8), account: account)
    }

    func load() -> String? {
        guard let data = KeychainStore.load(account: account) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func clear() {
        KeychainStore.delete(account: account)
    }
}

final class InMemoryTokenStore: TokenStore {
    private var token: String?

    func save(_ token: String) {
        self.token = token
    }

    func load() -> String? {
        token
    }

    func clear() {
        token = nil
    }
}

