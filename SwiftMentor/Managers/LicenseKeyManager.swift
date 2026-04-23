import Foundation
import CryptoKit

struct LicenseKey {
    let rawValue: String
    let type: LicenseType
    let isValid: Bool
    let expirationDate: Date?
    
    enum LicenseType: String {
        case personal = "P"
        case commercial = "C"
        case developer = "D"
        case educational = "E"
    }
}

class LicenseKeyManager {
    static let shared = LicenseKeyManager()
    
    // Load secrets from Secrets loader (reads from .xcconfig file)
    private let secretKey: String
    private let checksumSalt: String
    
    init() {
        self.secretKey = Secrets.licenseSecretKey
        self.checksumSalt = Secrets.licenseChecksumSalt
    }
    
    func validateKey(_ key: String) -> LicenseKey {
        guard isValidFormat(key) else {
            return LicenseKey(rawValue: key, type: .personal, isValid: false, expirationDate: nil)
        }
        
        let components = key.split(separator: "-").map(String.init)
        guard components.count == 4 else {
            return LicenseKey(rawValue: key, type: .personal, isValid: false, expirationDate: nil)
        }
        
        let prefix = components[0]
        let typeYear = components[1]
        let uniqueId = components[2]
        let checksum = components[3]
        
        guard prefix == "SWFT" else {
            return LicenseKey(rawValue: key, type: .personal, isValid: false, expirationDate: nil)
        }
        
        let typeChar = String(typeYear.prefix(1))
        guard let type = LicenseKey.LicenseType(rawValue: typeChar) else {
            return LicenseKey(rawValue: key, type: .personal, isValid: false, expirationDate: nil)
        }
        
        let keyWithoutChecksum = "\(prefix)-\(typeYear)-\(uniqueId)"
        let expectedChecksum = calculateChecksum(for: keyWithoutChecksum)
        
        guard checksum == expectedChecksum else {
            return LicenseKey(rawValue: key, type: .personal, isValid: false, expirationDate: nil)
        }
        
        return LicenseKey(rawValue: key, type: type, isValid: true, expirationDate: nil)
    }
    
    func storeLicenseKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "ActiveLicenseKey")
        if let keyData = key.data(using: .utf8) {
            KeychainHelper.save(data: keyData, forKey: "ActiveLicenseKey")
        }
    }
    
    func getStoredLicenseKey() -> String? {
        if let data = KeychainHelper.loadData(forKey: "ActiveLicenseKey"),
           let key = String(data: data, encoding: .utf8) {
            return key
        }
        return UserDefaults.standard.string(forKey: "ActiveLicenseKey")
    }
    
    func hasValidLicense() -> Bool {
        guard let key = getStoredLicenseKey() else { return false }
        return validateKey(key).isValid
    }
    
    func removeLicenseKey() {
        UserDefaults.standard.removeObject(forKey: "ActiveLicenseKey")
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrAccount as String: "ActiveLicenseKey"]
        SecItemDelete(query as CFDictionary)
    }
    
    // Gumroad integration
    func validateGumroadKey(_ key: String) -> LicenseKey? {
        guard !key.isEmpty && key.count >= 8 else {
            return nil
        }
        
        return LicenseKey(
            rawValue: "GUMRD-\(key.uppercased())",
            type: .personal,
            isValid: true,
            expirationDate: nil
        )
    }
    
    func isGumroadKey(_ key: String) -> Bool {
        return key.hasPrefix("GUMRD-") || key.hasPrefix("GUMROAD")
    }
    
    private func isValidFormat(_ key: String) -> Bool {
        let pattern = "^SWFT-[PCDE][A-Z][0-9][A-Z]-[A-Z0-9]{4}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: key)
    }
    
    private func calculateChecksum(for key: String) -> String {
        let message = "\(key)\(checksumSalt)"
        let keyData = Data(secretKey.utf8)
        let messageData = Data(message.utf8)
        let hmac = HMAC<SHA256>(key: keyData)
        let digest = try! hmac.update(data: messageData)
        let final = try! hmac.finalize()
        let hashBytes = Array(final)
        let hashString = hashBytes.map { String(format: "%02x", $0) }.joined()
        return String(hashString.prefix(4).uppercased())
    }
}

extension KeychainHelper {
    static func save(data: Data, forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    static func loadData(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return data
    }
}
