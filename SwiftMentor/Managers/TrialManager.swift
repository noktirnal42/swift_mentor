import Foundation
import Security

/// Manages the 30-day trial period for SwiftMentor
class TrialManager {
    static let shared = TrialManager()
    
    private let trialDays = 30
    private let firstLaunchKey = "com.swiftmentor.firstLaunchDate"
    
    func isTrialExpired() -> Bool {
        let firstLaunch = getFirstLaunchDate()
        let daysSinceLaunch = Calendar.current.dateComponents(.day, from: firstLaunch, to: Date()).day ?? 0
        return daysSinceLaunch >= trialDays
    }
    
    func daysRemaining() -> Int {
        if isTrialExpired() { return 0 }
        let firstLaunch = getFirstLaunchDate()
        let daysUsed = Calendar.current.dateComponents(.day, from: firstLaunch, to: Date()).day ?? 0
        return max(0, trialDays - daysUsed)
    }
    
    private func getFirstLaunchDate() -> Date {
        if let existing = UserDefaults.standard.object(forKey: firstLaunchKey) as? Date {
            return existing
        }
        let now = Date()
        storeFirstLaunchDate(now)
        return now
    }
    
    private func storeFirstLaunchDate(_ date: Date) {
        UserDefaults.standard.set(date, forKey: firstLaunchKey)
        KeychainHelper.save(date: date, forKey: firstLaunchKey)
        saveTimestampToFile(date)
    }
    
    private func saveTimestampToFile(_ date: Date) {
        let fm = FileManager.default
        if let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let dir = appSupport.appendingPathComponent("SwiftMentor", isDirectory: true)
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
            let file = dir.appendingPathComponent(".trial_timestamp")
            try? "\(date.timeIntervalSince1970)".write(to: file, atomically: true, encoding: .utf8)
        }
    }
}

class KeychainHelper {
    static func save(date: Date, forKey key: String) {
        guard let data = try? JSONEncoder().encode(date) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    static func loadDate(forKey key: String) -> Date? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data,
              let date = try? JSONDecoder().decode(Date.self, from: data) else { return nil }
        return date
    }
}
