import Foundation

/// Gumroad integration for license validation
extension LicenseKeyManager {
    /// Validate a Gumroad license key
    /// Gumroad keys format: Usually just alphanumeric, we'll accept and validate them
    func validateGumroadKey(_ key: String) -> LicenseKey? {
        // Gumroad keys are typically simpler, we'll convert to our format
        // or create a new format for Gumroad-specific keys
        
        // For now, we'll accept Gumroad keys as-is and store them
        // You can customize the validation logic based on Gumroad's format
        
        guard !key.isEmpty && key.count >= 8 else {
            return nil
        }
        
        // Create a wrapper license key for Gumroad
        return LicenseKey(
            rawValue: "GUMRD-\(key.uppercased())",
            type: .personal,
            isValid: true,
            expirationDate: nil
        )
    }
    
    /// Check if a key is from Gumroad
    func isGumroadKey(_ key: String) -> Bool {
        return key.hasPrefix("GUMRD-") || key.hasPrefix("GUMROAD")
    }
}
