import Foundation

/// Securely loads secrets from local configuration file
/// This avoids needing Xcode project configuration
struct Secrets {
    private static let configPath: String = {
        // Look for Secrets.xcconfig in the app bundle or local directory
        let paths = [
            Bundle.main.path(forResource: "Secrets", ofType: "xcconfig"),
            Bundle.main.resourcePath.map { "\($0)/Secrets.xcconfig" },
            "\(Bundle.main.resourcePath)/../Config/Secrets.xcconfig",
            "\(Bundle.main.bundlePath)/../Config/Secrets.xcconfig"
        ].compactMap { $0 }
        
        return paths.first ?? ""
    }()
    
    /// Load LemonSqueezy API key
    static var lemonSqueezyAPIKey: String {
        if let key = loadValue(forKey: "LEMONSQUEEZY_API_KEY") {
            return key
        }
        // Fallback to environment variable
        return ProcessInfo.processInfo.environment["LEMONSQUEEZY_API_KEY"] 
            ?? ""
    }
    
    /// Load license validation secret
    static var licenseSecretKey: String {
        if let key = loadValue(forKey: "LICENSE_SECRET_KEY") {
            return key
        }
        return ProcessInfo.processInfo.environment["LICENSE_SECRET_KEY"] 
            ?? "default_secret_change_in_production"
    }
    
    /// Load license checksum salt
    static var licenseChecksumSalt: String {
        if let key = loadValue(forKey: "LICENSE_CHECKSUM_SALT") {
            return key
        }
        return ProcessInfo.processInfo.environment["LICENSE_CHECKSUM_SALT"] 
            ?? "default_salt_change_in_production"
    }
    
    /// Helper to parse .xcconfig file
    private static func loadValue(forKey key: String) -> String? {
        guard FileManager.default.fileExists(atPath: configPath) else {
            return nil
        }
        
        guard let content = try? String(contentsOfFile: configPath, encoding: .utf8) else {
            return nil
        }
        
        // Parse .xcconfig format: KEY = value
        for line in content.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Skip comments and empty lines
            if trimmed.isEmpty || trimmed.hasPrefix("//") {
                continue
            }
            
            // Parse KEY = value
            let parts = trimmed.split(separator: "=", maxSplits: 1)
            if parts.count == 2 {
                let keyPart = String(parts[0]).trimmingCharacters(in: .whitespaces)
                let valuePart = String(parts[1]).trimmingCharacters(in: .whitespaces)
                
                if keyPart == key {
                    return valuePart
                }
            }
        }
        
        return nil
    }
}
