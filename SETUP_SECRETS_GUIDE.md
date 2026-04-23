# 🔐 Complete Guide: Setting Up Secrets Securely

## ✅ What We've Done

1. Created secure configuration system
2. Updated `.gitignore` to exclude secrets
3. Modified `LicenseKeyManager.swift` to use environment variables
4. Created template file you CAN commit

## 🚀 Step-by-Step Setup

### Step 1: Make Repository Private (CRITICAL!)

**Before adding ANY secrets, make your repo private:**

1. Go to: `https://github.com/noktirnal42/swift_mentor/settings`
2. Scroll to bottom → **"Danger Zone"**
3. Click **"Change visibility"**
4. Select **"Make private"**
5. Confirm

✅ Your repo is now private!

### Step 2: Add Your Secrets

1. Open: `/Users/jeremymcvay/dev/swift_tutor/SwiftMentor/Config/Secrets.xcconfig`

2. Replace the placeholders:
   ```swift
   // Your NEW LemonSqueezy API key
   LEMONSQUEEZY_API_KEY = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9..."
   
   // Generate random strings for these (use random text)
   LICENSE_SECRET_KEY = "MyUniqueSecretKey_2026_ChangeMe123!"
   LICENSE_CHECKSUM_SALT = "MyUniqueSalt_2026_ChangeMe456!"
   ```

3. Save the file

### Step 3: Configure Xcode Project

You need to tell Xcode to load these variables:

**Option A: Add to Info.plist (Simpler)**

1. Open `SwiftMentor/Info.plist`
2. Add these entries:
   ```xml
   <key>LICENSE_SECRET_KEY</key>
   <string>$(LICENSE_SECRET_KEY)</string>
   
   <key>LICENSE_CHECKSUM_SALT</key>
   <string>$(LICENSE_CHECKSUM_SALT)</string>
   ```

**Option B: Build Settings (Recommended)**

1. Open `SwiftMentor.xcodeproj` in Xcode
2. Select your project → Build Settings
3. Search for "Swift Compiler - Custom Flags"
4. Add: `-D LICENSE_SECRET_KEY=\"YourKey\"`

Actually, for macOS apps, the easiest way is:

### Step 4: Easiest Method - Use .xcconfig in Project

1. Open your Xcode project
2. File → Add Files to "SwiftMentor"
3. Select `SwiftMentor/Config/Secrets.xcconfig`
4. Make sure "Copy items if needed" is UNCHECKED
5. In project settings → Info tab:
   - Find "Configurations"
   - For Debug: Select `Secrets.xcconfig`
   - For Release: Select `Secrets.xcconfig`

### Step 5: Test It Works

1. Build and run your app
2. Try entering a license key
3. It should validate correctly

## 📁 File Structure

Your project now looks like this:

```
swift_mentor/
├── .gitignore                 ✅ Includes *.xcconfig
├── SwiftMentor/
│   ├── Config/
│   │   ├── Secrets.xcconfig   ❌ DO NOT COMMIT (in .gitignore)
│   │   └── Secrets.xcconfig.template ✅ CAN commit
│   ├── Managers/
│   │   └── LicenseKeyManager.swift ✅ Uses env vars
│   └── ...
└── SETUP_SECRETS_GUIDE.md     ✅ This file
```

## 🔒 Security Best Practices

### ✅ DO:
- Keep `Secrets.xcconfig` in your local directory only
- Use `.gitignore` to prevent accidental commits
- Use the template file for sharing structure
- Generate random, unique secrets
- Keep repo private

### ❌ DON'T:
- Never commit actual secrets to git
- Never share your `Secrets.xcconfig` file
- Never use default/obvious secrets
- Never commit API keys to public repos
- Share API keys in chat, email, etc.

## 🚨 If You Accidentally Commit Secrets

1. **IMMEDIATELY** revoke the exposed key
2. Generate new keys
3. Update `Secrets.xcconfig`
4. Commit the change
5. Git history still has it - consider rotating keys again

## 📝 For Your Gumroad Integration

When you add Gumroad, add to `Secrets.xcconfig`:

```swift
GUMROAD_PRODUCT_ID = "your_gumroad_product_id"
GUMROAD_PUBLISHER_TOKEN = "your_publisher_token"
```

## 🎯 Quick Checklist

- [ ] Repository is PRIVATE
- [ ] Created `Secrets.xcconfig` with real keys
- [ ] Added `Secrets.xcconfig` to Xcode project
- [ ] Tested that app builds and runs
- [ ] Verified license validation works
- [ ] Confirmed `Secrets.xcconfig` is in `.gitignore`
- [ ] Committed only the template, not actual secrets

## 💡 Pro Tips

1. **Backup your secrets:** Keep a secure backup of your `Secrets.xcconfig` somewhere safe (encrypted password manager, etc.)

2. **Use different keys for dev/prod:** Create separate configs for development and production

3. **Rotate regularly:** Change your secrets periodically

4. **Use environment variables in CI/CD:** If you add CI later, inject secrets there

## ❓ Questions?

**Q: What if I lose my Secrets.xcconfig?**
A: Just create a new one with new keys. No data loss, just regenerate.

**Q: Can I commit Secrets.xcconfig if repo is private?**
A: Technically yes, but still not recommended. Best practice is keep it local.

**Q: What about team members?**
A: Share the template file, each person creates their own Secrets.xcconfig with their own keys.

---

**Status:** Ready to Configure  
**Next Step:** Add your actual API key and secrets to `Secrets.xcconfig`
