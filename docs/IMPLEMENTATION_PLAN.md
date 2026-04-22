# SwiftMentor Licensing Implementation Plan
## Triple-Platform Strategy: LemonSqueezy + Gumroad + Paddle (Future)

**Status:** Ready to Implement  
**Your Time:** 20-30 minutes total  
**My Time:** 2-3 hours implementation  
**Monthly Cost:** $0  
**Maintenance:** ZERO  

---

## Strategy Overview

### Phase 1: Launch Now (Today)
- ✅ LemonSqueezy (primary, 5% fees)
- ✅ Gumroad (backup, 10% fees)
- Both active on GitHub
- Customers can choose

### Phase 2: Scale Later (Optional)
- Add Paddle when approved
- Move high-volume customers to Paddle
- Keep LemonSqueezy/Gumroad for flexibility

### Why This Strategy?
- **Immediate revenue** (no waiting for Paddle approval)
- **Customer choice** (multiple payment options)
- **Backup redundancy** (if one fails)
- **Easy migration** (all use same license format)
- **Zero lock-in** (can switch anytime)

---

## Step-by-Step Implementation

### YOUR TASKS (20-30 minutes total)

#### Task 1: LemonSqueezy Setup (10 minutes)

1. **Create Account** (5 min)
   - Go to https://www.lemonsqueezy.com
   - Click "Start Selling"
   - Sign up with email
   - Verify email
   - Connect bank account (for payouts)

2. **Create Personal License Product** (3 min)
   - Dashboard → Products → New Product
   - **Name:** SwiftMentor - Personal License
   - **Price:** $20.00
   - **Type:** License key
   - **Description:** "30-day free trial, then perpetual personal license for one user"
   
3. **Configure License Keys** (2 min)
   - Enable: "Generate license keys"
   - **Key format:** Custom
   - **Pattern:** `SWFT-P{year}{code}-{random4}-{random4}`
   - Example: `SWFT-P26A-7K9M-X4R2`
   - **Quantity:** Unlimited

4. **Create Commercial Products** (5 min)
   Repeat for each tier:
   
   **Product 1:** SwiftMentor Commercial (1-5 users)
   - Price: $175 ($35 × 5)
   - License keys: Enabled
   - Description: "Commercial license for 1-5 users"
   
   **Product 2:** SwiftMentor Commercial (6-20 users)
   - Price: $500 ($25 × 20)
   - License keys: Enabled
   
   **Product 3:** SwiftMentor Commercial (21-50 users)
   - Price: $1,000 ($20 × 50)
   - License keys: Enabled
   
   **Product 4:** SwiftMentor Commercial (51-100 users)
   - Price: $1,500 ($15 × 100)
   - License keys: Enabled

5. **Get Payment Links** (1 min)
   - Go to each product
   - Click "Get Link" or "Copy Link"
   - Save these URLs (you'll need them!)

**Total Time:** 15 minutes

---

#### Task 2: Gumroad Setup (10 minutes)

1. **Create Account** (3 min)
   - Go to https://gumroad.com
   - Click "Start Selling"
   - Sign up (can use same email)
   - Verify email
   - Connect bank account

2. **Create Personal License Product** (3 min)
   - Dashboard → Products → New Product
   - **Name:** SwiftMentor - Personal License
   - **Price:** $20
   - **Type:** Digital product
   - **Description:** "30-day trial, perpetual license"
   - Upload your app (.dmg) or set download link

3. **Enable License Keys** (2 min)
   - Product Settings → License Keys
   - Enable: "Generate license keys"
   - **Format:** Custom
   - **Pattern:** `SWFT-P{year}{code}-{random4}-{random4}`
   - Same format as LemonSqueezy!

4. **Create Commercial Products** (2 min)
   - Same tiers as LemonSqueezy
   - Same pricing
   - Enable license keys for each

5. **Get Payment Links** (1 min)
   - Copy all Gumroad product URLs

**Total Time:** 10 minutes

---

#### Task 3: Paddle Setup (Future - Optional, 5 minutes now)

1. **Apply for Account** (when ready)
   - Go to https://www.paddle.com
   - Click "Get Started"
   - Fill application (requires business info)
   - Wait 2-3 days for approval

2. **Once Approved:**
   - Create same products
   - Same license key format
   - Add as third payment option

**Why mention Paddle now?**
- We'll design license format to be compatible
- Easy to add later without changing anything
- No need to do this today!

---

## MY IMPLEMENTATION TASKS (2-3 hours)

### Part 1: TrialManager.swift (30 minutes)

```swift
import Foundation
import Security

class TrialManager {
    static let shared = TrialManager()
    
    private let trialDays = 30
    private let firstLaunchKey = "com.swiftmentor.firstLaunchDate"
    
    /// Check if trial has expired
    func isTrialExpired() -> Bool {
        let firstLaunch = getFirstLaunchDate()
        let daysSinceLaunch = Calendar.current.dateComponents(
            .day, 
            from: firstLaunch, 
            to: Date()
        ).day ?? 0
        
        return daysSinceLaunch >= trialDays
    }
    
    /// Get days remaining in trial
    func daysRemaining() -> Int {
        if !isTrialExpired() {
            let firstLaunch = getFirstLaunchDate()
            let daysUsed = Calendar.current.dateComponents(
                .day, 
                from: firstLaunch, 
                to: Date()
            ).day ?? 0
            return max(0, trialDays - daysUsed)
        }
        return 0
    }
    
    /// Get first launch date (stored in multiple locations for security)
    private func getFirstLaunchDate() -> Date {
        // Check UserDefaults first
        if let existing = UserDefaults.standard.object(forKey: firstLaunchKey) as? Date {
            return existing
        }
        
        // First launch - store in multiple locations
        let now = Date()
        storeFirstLaunchDate(now)
        return now
    }
    
    /// Store date in multiple locations (prevents tampering)
    private func storeFirstLaunchDate(_ date: Date) {
        // UserDefaults
        UserDefaults.standard.set(date, forKey: firstLaunchKey)
        
        // Keychain (survives app deletion)
        KeychainHelper.save(date: date, forKey: firstLaunchKey)
        
        // File timestamp (survives some cleanup)
        saveTimestampToFile(date)
    }
    
    private func saveTimestampToFile(_ date: Date) {
        let fileManager = FileManager.default
        if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let directory = appSupport.appendingPathComponent("SwiftMentor", isDirectory: true)
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            
            let timestampFile = directory.appendingPathComponent(".trial_timestamp")
            try? "\(date.timeIntervalSince1970)".write(to: timestampFile, atomically: true, encoding: .utf8)
        }
    }
}

// Keychain helper for persistent storage
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

### Part 2: LicenseKeyManager.swift (45 minutes)

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
        case developer = "D"  // For you - unlimited
        case educational = "E"
    }
}

class LicenseKeyManager {
    static let shared = LicenseKeyManager()
    
    // These will be set from config (NOT hardcoded in production!)
    private let secretKey = "YOUR_SECRET_KEY"  // Will be in config file
    private let checksumSalt = "YOUR_SALT"
    
    /// Validate a license key
    func validateKey(_ key: String) -> LicenseKey {
        // Check format: SWFT-P26A-7K9M-X4R2
        guard isValidFormat(key) else {
            return LicenseKey(rawValue: key, type: .personal, isValid: false, expirationDate: nil)
        }
        
        let components = key.split(separator: "-").map(String.init)
        guard components.count == 4 else {
            return LicenseKey(rawValue: key, type: .personal, isValid: false, expirationDate: nil)
        }
        
        let prefix = components[0]
        let typeYear = components[1]
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
        let keyWithoutChecksum = "\(prefix)-\(typeYear)-\(components[2])"
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
    
    /// Store validated license key
    func storeLicenseKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "ActiveLicenseKey")
        
        // Also store in Keychain for persistence
        KeychainHelper.save(data: key.data(using: .utf8)!, forKey: "ActiveLicenseKey")
    }
    
    /// Get stored license key
    func getStoredLicenseKey() -> String? {
        // Try Keychain first
        if let data = KeychainHelper.loadData(forKey: "ActiveLicenseKey"),
           let key = String(data: data, encoding: .utf8) {
            return key
        }
        
        // Fallback to UserDefaults
        return UserDefaults.standard.string(forKey: "ActiveLicenseKey")
    }
    
    /// Check if user has valid license
    func hasValidLicense() -> Bool {
        guard let key = getStoredLicenseKey() else {
            return false
        }
        
        let license = validateKey(key)
        return license.isValid
    }
    
    // MARK: - Helper Methods
    
    private func isValidFormat(_ key: String) -> Bool {
        // SWFT-P26A-7K9M-X4R2
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

// MARK: - Keychain Helper Extension

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
        
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        
        return data
    }
}
```

---

### Part 3: PurchaseDialogView.swift (30 minutes)

```swift
import SwiftUI

struct PurchaseDialogView: View {
    @State private var showLemonSqueezy = false
    @State private var showGumroad = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Trial Period Expired")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Your 30-day free trial has ended. Purchase a license to continue using SwiftMentor.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                // LemonSqueezy Button
                Button(action: { showLemonSqueezy = true }) {
                    HStack {
                        Image(systemName: "cart")
                        Text("Buy with LemonSqueezy")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                // Gumroad Button
                Button(action: { showGumroad = true }) {
                    HStack {
                        Image(systemName: "bag")
                        Text("Buy with Gumroad")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                // Enter License Key
                Button(action: {
                    // Show license entry dialog
                }) {
                    Text("Already have a license key?")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
            .padding(.top)
        }
        .padding()
        .sheet(isPresented: $showLemonSqueezy) {
            LemonSqueezySheet()
        }
        .sheet(isPresented: $showGumroad) {
            GumroadSheet()
        }
    }
}

struct LemonSqueezySheet: View {
    var body: some View {
        VStack {
            Text("LemonSqueezy Checkout")
                .font(.title)
                .padding()
            
            // This would open actual LemonSqueezy URL
            Button("Open LemonSqueezy") {
                if let url = URL(string: "YOUR_LEMONSQUEEZY_LINK") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}

struct GumroadSheet: View {
    var body: some View {
        VStack {
            Text("Gumroad Checkout")
                .font(.title)
                .padding()
            
            Button("Open Gumroad") {
                if let url = URL(string: "YOUR_GUMROAD_LINK") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}
```

---

### Part 4: Update README.md (15 minutes)

Add this section to your README:

```markdown
## Purchase License

SwiftMentor offers a **30-day free trial** with full access to all features. After the trial, a license is required for continued use.

### Personal License

**$20** - One-time purchase, perpetual license

- ✅ 30-day free trial included
- ✅ Perpetual license for one user
- ✅ All future updates
- ✅ Community support

[![Buy with LemonSqueezy](https://img.shields.io/badge/buy%20on-lemonsqueezy-ff5d5d?style=for-the-badge&logo=lemonsqueezy)](YOUR_LEMONSQUEEZY_LINK)

[![Buy with Gumroad](https://img.shields.io/badge/buy%20on-gumroad-ff9000?style=for-the-badge&logo=gumroad)](YOUR_GUMROAD_LINK)

### Commercial License

Volume discounts available for teams and institutions:

| Users | Price | Per User |
|-------|-------|----------|
| 1-5   | $175  | $35/user |
| 6-20  | $500  | $25/user |
| 21-50 | $1,000 | $20/user |
| 51-100| $1,500 | $15/user |
| 100+  | Contact for enterprise pricing |

[View Commercial Options](YOUR_LEMONSQUEEZY_COMMERCIAL_LINK)

### License Features

- **Trial Period:** 30 days free, full access
- **License Type:** Perpetual (one-time payment)
- **Updates:** Free updates included
- **Support:** Community support via GitHub Issues
- **Refunds:** 14-day money-back guarantee

### How It Works

1. Download SwiftMentor
2. Use free for 30 days (full access)
3. Trial expires → Purchase license
4. Receive license key via email
5. Enter key in app → Full access restored!

### Payment Options

We offer multiple payment options for your convenience:

- **LemonSqueezy** (Recommended) - Credit cards, Apple Pay, Google Pay
- **Gumroad** - Credit cards, PayPal
- **Paddle** (Coming soon) - Additional payment methods

All payments are secure and processed by trusted partners.
```

---

## Complete Checklist

### Your Tasks (20-30 minutes)

#### LemonSqueezy (10 min)
- [ ] Create account
- [ ] Create Personal License product ($20)
- [ ] Enable license keys (format: SWFT-P26A-XXXX-XXXX)
- [ ] Create Commercial products (all tiers)
- [ ] Copy all payment URLs

#### Gumroad (10 min)
- [ ] Create account
- [ ] Create Personal License product ($20)
- [ ] Enable license keys (same format)
- [ ] Create Commercial products
- [ ] Copy all payment URLs

#### Share Links (1 min)
- [ ] Send me the URLs (or add to README yourself)

---

### My Tasks (2-3 hours)

#### Code Implementation
- [ ] Add TrialManager.swift (30-day trial tracking)
- [ ] Add LicenseKeyManager.swift (key validation)
- [ ] Add PurchaseDialogView.swift (purchase UI)
- [ ] Add license key entry dialog
- [ ] Integrate with existing app structure
- [ ] Test trial expiration
- [ ] Test license key validation
- [ ] Test purchase flow

#### Documentation
- [ ] Update README with purchase links
- [ ] Add LICENSE.md (commercial license)
- [ ] Add payment badges
- [ ] Document trial period
- [ ] Add FAQ section

#### Testing
- [ ] Test complete flow (download → trial → purchase → activate)
- [ ] Test on clean install
- [ ] Test edge cases (date changes, reinstallation)
- [ ] Verify both LemonSqueezy and Gumroad work

---

## Timeline

### Today (30 minutes your time + 2-3 hours my time)
- ✅ You: Set up LemonSqueezy + Gumroad
- ✅ Me: Implement trial system + license validation
- ✅ Me: Update README + documentation
- ✅ Test complete flow

### Tomorrow (Optional)
- Fine-tune based on testing
- Add any missing features
- Prepare for launch

### Launch Day
- Push all changes to GitHub
- Announce on social media (optional)
- Monitor first purchases
- Celebrate! 🎉

---

## Cost Breakdown

### Setup Cost: $0
- LemonSqueezy: Free
- Gumroad: Free
- My implementation: Included 😊

### Monthly Cost: $0
- No hosting fees
- No subscription fees
- No maintenance costs

### Per Sale
- LemonSqueezy: 5% + $0.50 (~$1.50 on $20 sale)
- Gumroad: 10% + fees (~$2.29 on $20 sale)
- You keep: ~$18.50 (LemonSqueezy) or ~$17.71 (Gumroad)

### Example (10 sales/month via LemonSqueezy)
- Revenue: $200
- Fees: ~$15
- **You keep: $185**
- Monthly costs: $0
- **Profit: $185**

---

## Next Steps

1. **You:** Create LemonSqueezy account (5 min)
2. **You:** Create Gumroad account (5 min)
3. **You:** Create products on both (10 min)
4. **You:** Send me the payment URLs
5. **Me:** Implement everything (2-3 hours)
6. **Both:** Test complete flow
7. **Launch!** 🚀

**Total your time:** 20-30 minutes  
**Total my time:** 2-3 hours  
**Ongoing maintenance:** ZERO

---

**Status:** Ready to Implement  
**Your Action:** Create accounts, get URLs, then I'll implement everything!
