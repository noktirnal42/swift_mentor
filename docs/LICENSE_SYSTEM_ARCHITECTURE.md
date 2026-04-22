# SwiftMentor Licensing System Architecture

**Status:** Implementation Ready  
**Protection:** Option A (License Key) + Option C (Trial Period)  
**Payment:** Square with Automatic Key Issuance

---

## System Overview

```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐
│   Swift     │      │   Square     │      │   Your      │
│  Mentor     │◄────►│  Payment     │◄────►│  Backend    │
│  App        │      │  Processor   │      │  Server     │
│             │      │              │      │  (Private)  │
└──────┬──────┘      └──────┬───────┘      └──────┬──────┘
       │                    │                      │
       │ 1. Trial starts    │                      │
       │    (30 days)       │                      │
       │                    │                      │
       │ 2. Trial expires   │                      │
       │    prompts purchase│                      │
       │                    │                      │
       │ 3. User clicks     │                      │
       │    "Buy License"   │                      │
       ├───────────────────►│                      │
       │                    │                      │
       │                    │ 4. Payment complete  │
       │                    ├─────────────────────►│
       │                    │                      │
       │                    │                      │ 5. Generate
       │                    │                      │    license key
       │                    │                      │
       │                    │ 6. Send key via      │
       │                    │    email             │
       │                    ├─────────────────────►│
       │                    │                      │
       │ 7. User enters     │                      │
       │    license key     │                      │
       ├───────────────────────────────────────────┤
       │                    │                      │
       │ 8. Validate key    │                      │
       │    (offline +      │                      │
       │     optional       │                      │
       │     online)        │                      │
       │                    │                      │
       │ 9. Full access     │                      │
       │    unlocked        │                      │
       └────────────────────────────────────────────┘
```

---

## Component 1: Trial Period Enforcement (Option C)

### TrialManager.swift

**Purpose:** Track and enforce 30-day trial period

**Implementation:**
```swift
import Foundation
import Security

class TrialManager {
    private enum Keys {
        static let firstLaunchDate = "com.swiftmentor.firstLaunchDate"
        static let trialDays = 30
    }
    
    /// Get the first launch date, storing it if this is the first launch
    func getFirstLaunchDate() -> Date {
        if let existing = UserDefaults.standard.object(forKey: Keys.firstLaunchDate) as? Date {
            return existing
        }
        
        // First launch - store date in multiple locations
        let now = Date()
        UserDefaults.standard.set(now, forKey: Keys.firstLaunchDate)
        
        // Store in Keychain (survives app deletion)
        KeychainHelper.save(date: now, forKey: Keys.firstLaunchDate)
        
        // Store as file timestamp (survives some cleanup tools)
        saveTimestampToFile(now)
        
        return now
    }
    
    /// Check if trial has expired
    func isTrialExpired() -> Bool {
        let firstLaunch = getFirstLaunchDate()
        let daysSinceLaunch = Calendar.current.dateComponents(
            .day, 
            from: firstLaunch, 
            to: Date()
        ).day ?? 0
        
        return daysSinceLaunch >= Keys.trialDays
    }
    
    /// Get days remaining in trial
    func daysRemaining() -> Int {
        if isTrialExpired {
            return 0
        }
        
        let firstLaunch = getFirstLaunchDate()
        let daysUsed = Calendar.current.dateComponents(
            .day, 
            from: firstLaunch, 
            to: Date()
        ).day ?? 0
        
        return max(0, Keys.trialDays - daysUsed)
    }
    
    /// Tamper detection - check multiple storage locations
    func validateTrialIntegrity() -> Bool {
        let userDefaultsDate = UserDefaults.standard.object(forKey: Keys.firstLaunchDate) as? Date
        let keychainDate = KeychainHelper.loadDate(forKey: Keys.firstLaunchDate)
        let fileDate = loadTimestampFromFile()
        
        // If any two match, use the earliest (prevents tampering)
        var dates: [Date] = []
        if let date = userDefaultsDate { dates.append(date) }
        if let date = keychainDate { dates.append(date) }
        if let date = fileDate { dates.append(date) }
        
        guard let earliest = dates.min() else {
            // No dates found - this is first launch
            return true
        }
        
        // Update all storage to earliest date (prevents backdating)
        let now = Date()
        if earliest < now {
            UserDefaults.standard.set(earliest, forKey: Keys.firstLaunchDate)
            KeychainHelper.save(date: earliest, forKey: Keys.firstLaunchDate)
            saveTimestampToFile(earliest)
        }
        
        return true
    }
    
    private func saveTimestampToFile(_ date: Date) {
        // Store as file modification time in app support directory
        let fileManager = FileManager.default
        if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let directory = appSupport.appendingPathComponent("SwiftMentor", isDirectory: true)
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            
            let timestampFile = directory.appendingPathComponent(".trial_timestamp")
            try? "\(date.timeIntervalSince1970)".write(to: timestampFile, atomically: true, encoding: .utf8)
        }
    }
    
    private func loadTimestampFromFile() -> Date? {
        let fileManager = FileManager.default
        if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let timestampFile = appSupport
                .appendingPathComponent("SwiftMentor/.trial_timestamp")
            
            if let content = try? String(contentsOf: timestampFile),
               let timestamp = Double(content) {
                return Date(timeIntervalSince1970: timestamp)
            }
        }
        return nil
    }
}
```

**Key Features:**
- ✅ Stores trial start date in 3 locations (UserDefaults, Keychain, File)
- ✅ Validates integrity across all locations
- ✅ Prevents backdating by using earliest date
- ✅ Keychain survives app deletion
- ✅ File timestamp survives some cleanup tools

---

## Component 2: License Key Validation (Option A)

### LicenseKeyManager.swift

**Purpose:** Generate, validate, and manage license keys

**License Key Format:**
```
SWFT-P26A-7K9M-X4R2-SQ1
│   │  │    │    │    └─ Checksum (4 chars)
│   │  │    │    └────── Year code (A=2024, B=2025, C=2026)
│   │  │    └─────────── Unique ID (4 chars)
│   │  └──────────────── Product type (P=Personal, C=Commercial)
│   └─────────────────── Prefix (SWFT = SwiftMentor)
└─────────────────────── Fixed format
```

**Implementation:**
```swift
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
        case developer = "D"  // Unlimited, for you
        case educational = "E"
    }
}

class LicenseKeyManager {
    private let secretKey: String  // Your secret key (NEVER commit this!)
    private let checksumSalt: String
    
    init(secretKey: String, checksumSalt: String) {
        self.secretKey = secretKey
        self.checksumSalt = checksumSalt
    }
    
    /// Generate a new license key
    func generateKey(type: LicenseKey.LicenseType, uniqueId: String? = nil) -> String {
        let prefix = "SWFT"
        let typeCode = type.rawValue
        
        // Year code (A=2024, B=2025, C=2026, etc.)
        let yearCode = yearCodeForCurrentYear()
        
        // Unique ID (random or provided)
        let uid = uniqueId ?? generateUniqueId()
        
        // Build key without checksum
        let keyWithoutChecksum = "\(prefix)-\(typeCode)\(yearCode)-\(uid)"
        
        // Calculate checksum
        let checksum = calculateChecksum(for: keyWithoutChecksum)
        
        // Final key: SWFT-P26A-7K9M-X4R2
        return "\(keyWithoutChecksum)-\(checksum)"
    }
    
    /// Validate a license key
    func validateKey(_ key: String) -> LicenseKey {
        // Check format
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
        
        // Verify prefix
        guard prefix == "SWFT" else {
            return LicenseKey(rawValue: key, type: .personal, isValid: false, expirationDate: nil)
        }
        
        // Verify type
        let typeChar = String(typeYear.prefix(1))
        guard let type = LicenseKey.LicenseType(rawValue: typeChar) else {
            return LicenseKey(rawValue: key, type: .personal, isValid: false, expirationDate: nil)
        }
        
        // Verify checksum
        let keyWithoutChecksum = "\(prefix)-\(typeYear)-\(uniqueId)"
        let expectedChecksum = calculateChecksum(for: keyWithoutChecksum)
        
        guard checksum == expectedChecksum else {
            return LicenseKey(rawValue: key, type: .personal, isValid: false, expirationDate: nil)
        }
        
        // Key is valid!
        return LicenseKey(
            rawValue: key,
            type: type,
            isValid: true,
            expirationDate: nil  // Perpetual license
        )
    }
    
    /// Optional: Online validation with your server
    func validateKeyOnline(_ key: String) async -> Bool {
        // This would call your backend to verify the key
        // against a database of issued keys
        guard let url = URL(string: "https://your-backend.com/api/validate-key") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "key": key,
            "machineId": getMachineId()
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let isValid = json["valid"] as? Bool else {
                return false
            }
            return isValid
        } catch {
            return false
        }
    }
    
    // MARK: - Helper Methods
    
    private func isValidFormat(_ key: String) -> Bool {
        // SWFT-P26A-7K9M-X4R2 (or with checksum: SWFT-P26A-7K9M-X4R2-AB12)
        let pattern = "^SWFT-[PCDE][A-Z][0-9][A-Z]-[A-Z0-9]{4}(-[A-Z0-9]{4})?$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: key)
    }
    
    private func generateUniqueId() -> String {
        // Generate 4 random uppercase alphanumeric characters
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"  // No confusing chars (I, O, 1, 0)
        return String((0..<4).map { _ in chars.randomElement()! })
    }
    
    private func yearCodeForCurrentYear() -> String {
        let year = Calendar.current.component(.year, from: Date())
        let baseYear = 2024
        let offset = year - baseYear
        let code = Character(UnicodeScalar(65 + offset)!)  // A=2024, B=2025, etc.
        return "\(code)"
    }
    
    private func calculateChecksum(for key: String) -> String {
        // Create checksum using HMAC-SHA256
        let message = "\(key)\(checksumSalt)"
        let keyData = Data(secretKey.utf8)
        let messageData = Data(message.utf8)
        
        let hmac = HMAC<SHA256>(key: keyData)
        let digest = try! hmac.update(data: messageData)
        let final = try! hmac.finalize()
        
        // Convert to 4 uppercase alphanumeric characters
        let hashBytes = Array(final)
        let hashString = hashBytes.map { String(format: "%02x", $0) }.joined()
        
        return String(hashString.prefix(4).uppercased())
    }
    
    private func getMachineId() -> String {
        // Generate unique machine ID
        // This is a simple implementation - you might want something more robust
        let macAddress = "unknown"  // Get actual MAC address if needed
        let hostname = Host.current().name ?? "unknown"
        let identifier = "\(macAddress)-\(hostname)"
        return identifier.sha256().prefix(16)
    }
}

// MARK: - Keychain Helper

class KeychainHelper {
    static func save(date: Date, forKey key: String) {
        let data = try? JSONEncoder().encode(date)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data!
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
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let date = try? JSONDecoder().decode(Date.self, from: data) else {
            return nil
        }
        
        return date
    }
}
```

---

## Component 3: Square Integration

### SquarePaymentManager.swift

**Purpose:** Handle Square payment flow and webhook integration

**Setup Steps:**

1. **Create Square Application:**
   - Go to https://squareup.com/developers
   - Create new application
   - Get Application ID and Access Token

2. **Create Payment Links:**
   - Square Dashboard → Online Checkout → Payment Links
   - Create products:
     - SwiftMentor Personal License ($20)
     - SwiftMentor Commercial License (various tiers)
   - Copy payment URLs

3. **Set Up Webhook:**
   - Square Dashboard → Settings → Notifications
   - Add webhook endpoint: `https://your-backend.com/square/webhook`
   - Subscribe to: `payment.updated` events

**Implementation:**
```swift
import Foundation

class SquarePaymentManager {
    static let shared = SquarePaymentManager()
    
    // Square Application ID (from Square Dashboard)
    private let applicationId = "YOUR_SQUARE_APPLICATION_ID"
    
    // Your backend webhook URL
    private let webhookUrl = "https://your-backend.com/square/webhook"
    
    /// Get payment URL for a specific product
    func getPaymentUrl(for product: LicenseProduct) -> URL? {
        switch product {
        case .personal:
            return URL(string: "https://square.link/u/YOUR_PERSONAL_LICENSE_LINK")
        case .commercial1to5:
            return URL(string: "https://square.link/u/YOUR_COMMERCIAL_1TO5_LINK")
        case .commercial6to20:
            return URL(string: "https://square.link/u/YOUR_COMMERCIAL_6TO20_LINK")
        case .commercial21to50:
            return URL(string: "https://square.link/u/YOUR_COMMERCIAL_21TO50_LINK")
        case .commercial51to100:
            return URL(string: "https://square.link/u/YOUR_COMMERCIAL_51TO100_LINK")
        }
    }
    
    /// Open Square payment in browser
    func openPayment(for product: LicenseProduct, from window: NSWindow) {
        guard let url = getPaymentUrl(for: product) else {
            print("Invalid payment URL")
            return
        }
        
        NSWorkspace.shared.open(url)
    }
    
    /// Check payment status (polling or webhook-based)
    func checkPaymentStatus(orderId: String, completion: @escaping (Bool, String?) -> Void) {
        // This would call your backend to check if payment completed
        // Your backend would check Square API or wait for webhook
        
        guard let url = URL(string: "https://your-backend.com/api/payment-status/\(orderId)") else {
            completion(false, "Invalid URL")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let isComplete = json["completed"] as? Bool,
                  let licenseKey = json["licenseKey"] as? String else {
                completion(false, "Payment verification failed")
                return
            }
            
            if isComplete {
                // Payment complete - validate and store license key
                let licenseManager = LicenseKeyManager(
                    secretKey: "YOUR_SECRET_KEY",
                    checksumSalt: "YOUR_SALT"
                )
                
                let license = licenseManager.validateKey(licenseKey)
                if license.isValid {
                    // Store license key
                    UserDefaults.standard.set(licenseKey, forKey: "LicenseKey")
                    completion(true, "License activated successfully!")
                } else {
                    completion(false, "Invalid license key received")
                }
            } else {
                completion(false, "Payment not yet complete")
            }
        }
        
        task.resume()
    }
}

enum LicenseProduct {
    case personal
    case commercial1to5
    case commercial6to20
    case commercial21to50
    case commercial51to100
}
```

---

## Component 4: Backend Service (Private - Keep OFF GitHub)

**Location:** Private repository or local server  
**Purpose:** Handle Square webhooks and generate license keys

**server.js (Node.js/Express example):**
```javascript
const express = require('express');
const crypto = require('crypto');
const sq = require('@squareup/square');
const app = express();

// Configuration
const SQUARE_ACCESS_TOKEN = 'YOUR_SQUARE_ACCESS_TOKEN';
const SECRET_KEY = 'YOUR_SECRET_KEY_FOR_KEYS';
const CHECKSUM_SALT = 'YOUR_CHECKSUM_SALT';

// Square SDK client
const client = new sq.Client({
  accessToken: SQUARE_ACCESS_TOKEN,
  environment: 'production' // or 'sandbox'
});

// Webhook endpoint for Square payments
app.post('/square/webhook', express.raw({type: 'application/json'}), async (req, res) => {
  const signature = req.headers['x-square-signature'];
  const body = req.body;
  
  // Verify webhook signature
  if (!verifyWebhookSignature(signature, body)) {
    return res.status(401).send('Invalid signature');
  }
  
  const event = JSON.parse(body.toString());
  
  if (event.type === 'payment.updated') {
    const payment = event.data.object.payment;
    
    if (payment.status === 'COMPLETED') {
      // Generate license key
      const licenseKey = generateLicenseKey('P'); // P = Personal
      
      // Send email with license key
      await sendLicenseEmail(payment.buyer_email, licenseKey);
      
      // Store in database
      await storeLicenseKey(licenseKey, payment.id);
    }
  }
  
  res.status(200).send('OK');
});

// Generate license key (same algorithm as Swift app)
function generateLicenseKey(type) {
  const prefix = 'SWFT';
  const typeCode = type;
  const yearCode = yearCodeForCurrentYear();
  const uniqueId = generateUniqueId();
  const keyWithoutChecksum = `${prefix}-${typeCode}${yearCode}-${uniqueId}`;
  const checksum = calculateChecksum(keyWithoutChecksum);
  
  return `${keyWithoutChecksum}-${checksum}`;
}

function calculateChecksum(key) {
  const message = `${key}${CHECKSUM_SALT}`;
  const hash = crypto.createHmac('sha256', SECRET_KEY)
    .update(message)
    .digest('hex');
  
  return hash.substring(0, 4).toUpperCase();
}

// Helper functions
function yearCodeForCurrentYear() {
  const year = new Date().getFullYear();
  const baseYear = 2024;
  const offset = year - baseYear;
  return String.fromCharCode(65 + offset); // A=2024, B=2025, etc.
}

function generateUniqueId() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let result = '';
  for (let i = 0; i < 4; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

async function sendLicenseEmail(email, licenseKey) {
  // Use SendGrid, Mailgun, or AWS SES to send email
  // Include license key and activation instructions
}

async function storeLicenseKey(licenseKey, paymentId) {
  // Store in database (PostgreSQL, MySQL, etc.)
  // for future validation
}

function verifyWebhookSignature(signature, body) {
  // Verify Square webhook signature
  // See Square documentation for details
  return true; // Placeholder
}

app.listen(3000, () => {
  console.log('License server running on port 3000');
});
```

---

## Security Considerations

### What to Keep OFF GitHub:

1. **Secret Keys:**
   - `SECRET_KEY` for license generation
   - `CHECKSUM_SALT`
   - Square Access Token
   - Any API keys

2. **Backend Code:**
   - License key generation algorithm
   - Webhook handler
   - Database logic
   - Email sending logic

3. **Customer Data:**
   - Payment information
   - Email addresses
   - License key database

### Where to Host Sensitive Code:

- **Private GitHub repository** (separate from public SwiftMentor repo)
- **Local development only** (never commit)
- **Encrypted files** if must be in repo
- **Environment variables** for secrets

### What CAN be on GitHub:

- Trial enforcement code (TrialManager.swift)
- License validation code (LicenseKeyManager.swift - without actual keys)
- Square payment UI code
- Public API documentation

---

## Implementation Checklist

### Phase 1: Trial Period (Option C)
- [ ] Add TrialManager.swift to project
- [ ] Implement first launch date tracking
- [ ] Add trial expiration check
- [ ] Create trial expiration UI
- [ ] Test trial flow

### Phase 2: License Keys (Option A)
- [ ] Add LicenseKeyManager.swift to project
- [ ] Implement key generation algorithm
- [ ] Implement key validation
- [ ] Create license key storage (UserDefaults + Keychain)
- [ ] Add license entry UI
- [ ] Test key validation

### Phase 3: Square Integration
- [ ] Create Square account (already done)
- [ ] Create payment links in Square Dashboard
- [ ] Add SquarePaymentManager.swift
- [ ] Implement payment flow
- [ ] Set up backend webhook endpoint
- [ ] Test payment → key generation flow

### Phase 4: Backend Service (Private)
- [ ] Set up private repository
- [ ] Create backend server (Node.js/Python/etc.)
- [ ] Implement Square webhook handler
- [ ] Implement license key generation
- [ ] Set up email service (SendGrid/Mailgun)
- [ ] Deploy backend (Heroku, AWS, etc.)
- [ ] Test complete flow

### Phase 5: Integration & Testing
- [ ] Replace MIT license with LICENSE.md
- [ ] Update README with purchase info
- [ ] Add purchase buttons to app
- [ ] Test complete user journey:
  - Download → Trial starts
  - Use for 30 days
  - Trial expires → Purchase prompt
  - Click purchase → Square payment
  - Payment complete → Email with key
  - Enter key → Full access unlocked
- [ ] Test edge cases:
  - System date change
  - App reinstall
  - Invalid keys
  - Network failures

---

## Cost Estimate

### Monthly Costs:
- **Square:** 2.9% + $0.30 per transaction (only when you sell)
- **Backend Hosting:** $0-10/month (Heroku free tier or AWS free tier)
- **Email Service:** $0-15/month (SendGrid free tier: 100 emails/day)
- **Domain:** ~$15/year (if needed)

### Total: ~$0-25/month to start

### Revenue Example:
- 10 personal licenses/month @ $20 = $200
- Square fees (2.9% + $0.30): ~$6
- Hosting/Email: ~$15
- **Net: ~$179/month**

---

## Next Steps

1. **Approve this architecture**
2. **Create Square payment links** (5 minutes)
3. **Set up backend** (private repo - I can help create)
4. **Implement TrialManager** in app (1-2 hours)
5. **Implement LicenseKeyManager** in app (2-3 hours)
6. **Test complete flow** (1 hour)
7. **Deploy and launch!**

**Total Implementation Time:** 1-2 days

---

**Status:** Ready for Implementation  
**Next Action:** Your approval to proceed with implementation
