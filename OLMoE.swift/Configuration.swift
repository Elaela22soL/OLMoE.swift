import Foundation

enum Configuration {
    enum Error: Swift.Error {
        case missingKey, invalidValue
    }

    static func value<T>(for key: String) throws -> T where T: LosslessStringConvertible {
        guard let object = Bundle.main.object(forInfoDictionaryKey: key) else {
            print("Configuration Error: Key '\(key)' not found in Info.plist")
            throw Error.missingKey
        }

        switch object {
        case let value as T:
            return value
        case let string as String:
            guard let value = T(string) else {
                print("Configuration Error: Value for key '\(key)' could not be converted to \(T.self)")
                throw Error.invalidValue
            }
            return value
        default:
            print("Configuration Error: Value for key '\(key)' is not of expected type \(T.self)")
            throw Error.invalidValue
        }
    }
}

extension Configuration {
    static var apiKey: String {
        do {
            return try Configuration.value(for: "API_KEY")
        } catch {
            print("Failed to retrieve API_KEY: \(error)")
            return "API_KEY_NOT_FOUND"
        }
    }
    static var apiUrl: String {
        do {
            return try Configuration.value(for: "API_URL")
        } catch {
            print("Failed to retrieve API_URL: \(error)")
            return "API_URL_NOT_FOUND"
        }
    }
    static var challenge: String {
        do {
            return try Configuration.value(for: "APP_ATTEST_TEMP_CHALLENGE")
        } catch {
            print("Failed to retrieve challenge: \(error)")
            return "ATTEST_FAILED"
        }
    }
}
