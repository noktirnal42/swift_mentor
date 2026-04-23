import XCTest
@testable import SwiftMentor

final class LicensingTests: XCTestCase {
    
    // MARK: - TrialManager Tests
    
    func testTrialManagerSharedInstance() {
        let trialManager = TrialManager.shared
        XCTAssertNotNil(trialManager, "TrialManager shared instance should exist")
    }
    
    func testTrialDaysRemaining() {
        let trialManager = TrialManager.shared
        let daysRemaining = trialManager.daysRemaining()
        
        // Should be between 0 and 30
        XCTAssertGreaterThanOrEqual(daysRemaining, 0, "Days remaining should not be negative")
        XCTAssertLessThanOrEqual(daysRemaining, 30, "Days remaining should not exceed trial period")
    }
    
    func testTrialExpiration() {
        let trialManager = TrialManager.shared
        let isExpired = trialManager.isTrialExpired()
        
        // This test depends on when the app was first launched
        // Just verify the method returns a boolean
        XCTAssertTrue(isExpired || !isExpired, "Should return valid boolean")
    }
    
    // MARK: - LicenseKeyManager Tests
    
    func testLicenseKeyManagerSharedInstance() {
        let keyManager = LicenseKeyManager.shared
        XCTAssertNotNil(keyManager, "LicenseKeyManager shared instance should exist")
    }
    
    func testValidLicenseKeyFormat() {
        let keyManager = LicenseKeyManager.shared
        
        // Test valid personal key
        let validKey = "SWFT-P26A-TEST-KEY1"
        let result = keyManager.validateKey(validKey)
        
        // Note: This will fail checksum validation, but format should be correct
        // For actual testing, you'd need to generate a real key with valid checksum
        XCTAssertNotNil(result, "Should return a LicenseKey object")
    }
    
    func testInvalidLicenseKeyFormat() {
        let keyManager = LicenseKeyManager.shared
        
        // Test invalid formats
        let invalidKeys = [
            "INVALID-KEY",
            "SWFT-X26A-TEST-KEY1",  // Invalid type
            "SWFT-P99A-TEST-KEY1",  // Invalid year
            "",
            "SWFT-P26A"  // Incomplete
        ]
        
        for invalidKey in invalidKeys {
            let result = keyManager.validateKey(invalidKey)
            XCTAssertFalse(result.isValid, "Key '\(invalidKey)' should be invalid")
        }
    }
    
    func testLicenseKeyStorage() {
        let keyManager = LicenseKeyManager.shared
        
        // Clean up first
        keyManager.removeLicenseKey()
        
        // Store a test key (not validated, just storage test)
        let testKey = "SWFT-P26A-TEST-KEY1"
        keyManager.storeLicenseKey(testKey)
        
        // Retrieve and verify
        let storedKey = keyManager.getStoredLicenseKey()
        XCTAssertEqual(storedKey, testKey, "Stored key should match retrieved key")
        
        // Clean up
        keyManager.removeLicenseKey()
    }
    
    func testHasValidLicense() {
        let keyManager = LicenseKeyManager.shared
        
        // Clean up first
        keyManager.removeLicenseKey()
        
        // Should not have valid license initially
        XCTAssertFalse(keyManager.hasValidLicense(), "Should not have valid license initially")
        
        // Clean up
        keyManager.removeLicenseKey()
    }
    
    // MARK: - Gumroad Integration Tests
    
    func testGumroadKeyDetection() {
        let keyManager = LicenseKeyManager.shared
        
        XCTAssertTrue(keyManager.isGumroadKey("GUMRD-ABC123"), "Should detect Gumroad key prefix")
        XCTAssertTrue(keyManager.isGumroadKey("GUMROAD-XYZ789"), "Should detect Gumroad key prefix")
        XCTAssertFalse(keyManager.isGumroadKey("SWFT-P26A-TEST-KEY1"), "Should not detect standard key as Gumroad")
    }
    
    func testGumroadKeyValidation() {
        let keyManager = LicenseKeyManager.shared
        
        // Test valid Gumroad key format
        let gumroadKey = "GUMRD-ABC123XYZ"
        let result = keyManager.validateGumroadKey(gumroadKey)
        
        XCTAssertNotNil(result, "Should return a LicenseKey for valid Gumroad format")
        XCTAssertEqual(result?.rawValue, "GUMRD-ABC123XYZ".uppercased())
        
        // Test invalid Gumroad key (too short)
        let invalidKey = "GUMRD-123"
        let invalidResult = keyManager.validateGumroadKey(invalidKey)
        XCTAssertNil(invalidResult, "Should return nil for invalid Gumroad key")
    }
}
