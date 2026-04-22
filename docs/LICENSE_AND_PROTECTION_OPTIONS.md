# SwiftMentor Licensing & Protection Options

**Document Purpose:** Present options for commercial licensing, copy protection, and payment processing for SwiftMentor.

**Date:** April 22, 2026  
**Status:** For Review & Approval

---

## Part 1: GitHub Terms of Service Analysis

### ✅ What GitHub ALLOWS:

1. **Commercial Projects on GitHub**
   - ✅ Allowed to host commercial software
   - ✅ Can use GitHub for both open-source and commercial projects
   - ✅ Can link to external payment processors

2. **Payment Links**
   - ✅ Can link to external payment processors (Gumroad, LemonSqueezy, etc.)
   - ✅ Can include purchase links in README
   - ✅ Can use GitHub Pages for commercial sites

3. **License Files**
   - ✅ Can replace MIT with commercial license
   - ✅ Can host LICENSE file with custom terms
   - ✅ Can enforce license terms

### ❌ What GitHub DOESN'T Allow:

1. **Native Payment Processing**
   - ❌ GitHub Sponsors only for developers/organizations (not product sales)
   - ❌ Cannot process payments directly through GitHub
   - ❌ GitHub Marketplace is for GitHub Apps only

2. **Prohibited Content**
   - ❌ Malware or intentionally harmful code
   - ❌ Credential harvesting
   - ❌ DRM that harms users (see protection options below)

### ✅ Recommended Approach:
**Use GitHub for code hosting + External services for licensing/payments**

---

## Part 2: Copy Protection Options

### Option A: License Key Validation (RECOMMENDED)

**How it works:**
1. App generates unique machine ID on first launch
2. User purchases license key from website
3. User enters key in app
4. App validates key format (offline) + optional online validation
5. Valid key unlocks full version

**Implementation:**
```swift
// License validation (simplified)
class LicenseManager {
    func validateKey(_ key: String) -> Bool {
        // Check format: SWFT-XXXX-XXXX-XXXX-XXXX
        // Check checksum
        // Optional: Online validation
    }
    
    func isTrialExpired() -> Bool {
        // Check first launch date
        // Compare to 30 days
    }
}
```

**Pros:**
- ✅ User-friendly
- ✅ Works offline (basic validation)
- ✅ Easy to implement
- ✅ GitHub ToS compliant
- ✅ Can generate keys for yourself (developer)

**Cons:**
- ⚠️ Can be cracked by determined users
- ⚠️ Requires key management system

**Developer Key Generation:**
- You can generate unlimited keys for yourself
- Use same validation algorithm
- Mark keys as "Developer" or "Unlimited"

---

### Option B: Hardware-Bound Licensing

**How it works:**
1. Generate unique ID from hardware (MAC address, disk serial, etc.)
2. Tie license to specific machine
3. User can activate on N machines (e.g., 3)

**Pros:**
- ✅ More secure than simple keys
- ✅ Prevents unlimited sharing
- ✅ Industry standard

**Cons:**
- ⚠️ More complex implementation
- ⚠️ Requires activation server (or offline algorithm)
- ⚠️ User must re-activate on hardware changes

---

### Option C: Time-Limited Trial with Feature Lock

**How it works:**
1. Track first launch date in multiple locations
2. After 30 days, lock premium features
3. Show purchase dialog
4. Basic features remain free (optional)

**Implementation:**
```swift
// Store trial start date in multiple places:
// - UserDefaults
// - Keychain
// - File system timestamp
// - System date (for tamper detection)

class TrialManager {
    func daysRemaining() -> Int {
        let startDate = getFirstLaunchDate()
        let daysUsed = Calendar.current.dateComponents(
            .day, 
            from: startDate, 
            to: Date()
        ).day ?? 0
        return max(0, 30 - daysUsed)
    }
}
```

**Pros:**
- ✅ Simple to implement
- ✅ Clear to users
- ✅ GitHub ToS compliant

**Cons:**
- ⚠️ Can be bypassed by changing system date
- ⚠️ Requires multiple storage locations

---

### Option D: Online License Server (Most Secure)

**How it works:**
1. App contacts your license server on launch
2. Server validates license key
3. Server tracks activations
4. App receives encrypted license token

**Pros:**
- ✅ Most secure option
- ✅ Real-time validation
- ✅ Can revoke compromised keys
- ✅ Track usage analytics

**Cons:**
- ⚠️ Requires server infrastructure
- ⚠️ Requires internet connection
- ⚠️ Higher maintenance
- ⚠️ Cost for server hosting

---

### ⚠️ Options to AVOID (GitHub ToS Concerns):

1. **Obfuscated Expiration Checking**
   - Don't hide trial checks in code
   - Don't use deceptive practices

2. **System Modification**
   - Don't modify system files
   - Don't install rootkits or persistent daemons

3. **Excessive Hardware Fingerprinting**
   - Don't collect unnecessary hardware data
   - Don't create persistent identifiers beyond license needs

4. **Anti-Debugging Tricks**
   - Don't crash when debugger detected
   - Don't use anti-analysis techniques

**GitHub's Stance:** Code should not be intentionally harmful or deceptive.

---

## Part 3: Payment Processing Options

### Option 1: Gumroad (RECOMMENDED for Start)

**Best for:** Simple setup, digital products

**Features:**
- ✅ Sell license keys automatically
- ✅ Deliver keys via email
- ✅ Handle VAT/taxes automatically
- ✅ PayPal + Credit Cards
- ✅ No monthly fee (only 10% + transaction fees)
- ✅ Can embed buy button on GitHub README

**Pricing:**
- Free plan: 10% fee + 2.9% + $0.30 per transaction
- Premium ($10/month): 5% fee + 2.9% + $0.30

**Integration:**
```markdown
[![Buy on Gumroad](https://img.shields.io/badge/buy-on%20gumroad-ff5d5d?style=for-the-badge)](https://gumroad.com/l/swiftmentor)
```

**Pros:**
- ✅ Easiest setup (minutes)
- ✅ Automatic license key delivery
- ✅ Handles EU VAT
- ✅ No monthly commitment
- ✅ GitHub ToS compliant

**Cons:**
- ⚠️ Higher fees than direct processing
- ⚠️ Less customization

**URL:** https://gumroad.com

---

### Option 2: LemonSqueezy (RECOMMENDED for Growth)

**Best for:** Software licensing, global sales

**Features:**
- ✅ Built for software/SaaS
- ✅ License key generation included
- ✅ Merchant of Record (handles taxes globally)
- ✅ 5% + $0.50 per transaction
- ✅ No monthly fee
- ✅ Beautiful checkout pages
- ✅ License key management API

**Pricing:**
- 5% + $0.50 per transaction
- No monthly fees

**Integration:**
- Buy button embed
- Direct links
- API for license validation

**Pros:**
- ✅ Built specifically for software
- ✅ License keys included
- ✅ Handles global taxes
- ✅ Professional checkout
- ✅ GitHub ToS compliant

**Cons:**
- ⚠️ Slightly higher fees than Stripe
- ⚠️ Less known than Gumroad

**URL:** https://www.lemonsqueezy.com

---

### Option 3: Paddle

**Best for:** Established software businesses

**Features:**
- ✅ Merchant of Record
- ✅ Global tax compliance
- ✅ License key management
- ✅ Subscription support
- ✅ 5% + $0.50 or custom pricing

**Pricing:**
- 5% + $0.50 per transaction
- Custom plans available

**Pros:**
- ✅ Full compliance handled
- ✅ Professional
- ✅ Supports subscriptions

**Cons:**
- ⚠️ More complex setup
- ⚠️ Approval process
- ⚠️ Better for established businesses

**URL:** https://www.paddle.com

---

### Option 4: Stripe (Advanced)

**Best for:** Full control, custom solutions

**Features:**
- ✅ Direct payment processing
- ✅ Lowest fees (2.9% + $0.30)
- ✅ Full customization
- ✅ Requires your own license system

**Pricing:**
- 2.9% + $0.30 per transaction
- No monthly fee

**Requirements:**
- Your own website
- License key generation system
- Payment form hosting
- Tax handling

**Pros:**
- ✅ Lowest fees
- ✅ Full control
- ✅ Professional

**Cons:**
- ⚠️ Most complex setup
- ⚠️ Need to build license system
- ⚠️ Responsible for tax compliance
- ⚠️ Need business entity

**URL:** https://stripe.com

---

### Option 5: GitHub Sponsors (NOT Recommended for This Use)

**Why NOT:**
- ❌ For sponsoring developers, not selling products
- ❌ No license key delivery
- ❌ No commercial license enforcement
- ❌ Not designed for software sales

**Better for:** Open-source funding, not commercial software

---

## Part 4: Recommended Solution Stack

### For Quick Start (Recommended):

**Licensing:** License Key Validation (Option A)
- Simple offline validation
- Generate keys manually or via payment processor
- Store first launch date in multiple locations

**Payment:** Gumroad or LemonSqueezy
- Gumroad: Easiest start (10% fee)
- LemonSqueezy: Better for software (5% fee)
- Both deliver license keys automatically
- Both handle taxes

**Implementation:**
1. Replace MIT license with LICENSE.md
2. Add license validation to app
3. Set up Gumroad/LemonSqueezy account
4. Generate license keys in payment processor
5. Add purchase link to README
6. Remove sensitive code from GitHub (key generator)

**Timeline:** 1-2 days to implement

---

### For Professional Launch:

**Licensing:** Hardware-Bound + Online Validation
**Payment:** LemonSqueezy or Paddle
**Infrastructure:** Simple license validation server

**Timeline:** 1-2 weeks

---

## Part 5: What to Keep OFF GitHub

### Files to EXCLUDE from repository:

1. **License Key Generator**
   - Algorithm for generating valid keys
   - Master key or signing certificate
   - Key generation script/app

2. **Payment Integration Code**
   - API keys for payment processors
   - Server-side validation code
   - Customer database

3. **License Validation Server**
   - Server code if using online validation
   - Database of valid keys
   - Customer information

4. **Sensitive Configuration**
   - Private keys
   - API secrets
   - Encryption keys

### Where to Host Sensitive Code:

- **Private repository** on GitHub
- **Separate private repo** for key generation
- **Local development only** (never commit)
- **Encrypted files** in repo (if must be on GitHub)

---

## Part 6: Implementation Checklist

### Phase 1: Licensing Foundation
- [ ] Replace MIT license with LICENSE.md
- [ ] Add license file to project
- [ ] Create LicenseManager class
- [ ] Implement trial period tracking
- [ ] Add license key validation
- [ ] Create developer key (unlimited for yourself)

### Phase 2: Payment Setup
- [ ] Choose payment processor (Gumroad recommended)
- [ ] Create product listings (Personal, Commercial tiers)
- [ ] Configure automatic license key delivery
- [ ] Test purchase flow
- [ ] Get purchase links

### Phase 3: Integration
- [ ] Add purchase UI to app
- [ ] Add license key entry UI
- [ ] Implement key validation
- [ ] Add trial expiration handling
- [ ] Test complete flow

### Phase 4: Documentation
- [ ] Update README with licensing info
- [ ] Add purchase badges/links
- [ ] Document trial period
- [ ] Add FAQ section
- [ ] Create LICENSE.md public page

### Phase 5: Launch
- [ ] Remove sensitive code from GitHub
- [ ] Add .gitignore for sensitive files
- [ ] Test clean install
- [ ] Verify trial works
- [ ] Verify purchase flow
- [ ] Deploy

---

## Part 7: Sample License Key Format

**Format:** `SWFT-XXXX-XXXX-XXXX-XXXX`

**Structure:**
- Prefix: `SWFT` (identifies SwiftMentor)
- Segment 1: Product type (P=Personal, C=Commercial)
- Segment 2: Year code
- Segment 3: Unique identifier
- Segment 4: Checksum

**Example:**
- `SWFT-P26A-7K9M-X4R2` = Personal license, 2026, unique ID, checksum

**Validation:**
1. Check format (regex)
2. Verify prefix
3. Calculate and verify checksum
4. Optional: Online validation

---

## Part 8: Next Steps

### Immediate Actions:
1. ✅ **Approve license text** (LICENSE.md drafted above)
2. ⏳ **Choose copy protection method** (recommend Option A)
3. ⏳ **Choose payment processor** (recommend Gumroad or LemonSqueezy)
4. ⏳ **Create payment processor account**
5. ⏳ **Generate first license keys**

### After Approval:
1. Implement license validation in app
2. Set up payment processor
3. Update README with purchase info
4. Remove sensitive code from GitHub
5. Test complete flow

---

## Questions for Approval:

### Copy Protection:
- [ ] **Option A:** Simple license key validation (Recommended)
- [ ] **Option B:** Hardware-bound licensing
- [ ] **Option C:** Time-limited trial with feature lock
- [ ] **Option D:** Online license server

### Payment Processor:
- [ ] **Gumroad** (easiest, 10% fee)
- [ ] **LemonSqueezy** (software-focused, 5% fee)
- [ ] **Paddle** (professional, 5% fee)
- [ ] **Stripe** (lowest fees, most complex)

### Pricing Confirmation:
- [ ] Personal: $20 after 30-day trial ✅
- [ ] Commercial Tier 1 (1-5): $35/user ✅
- [ ] Commercial Tier 2 (6-20): $25/user ✅
- [ ] Commercial Tier 3 (21-50): $20/user ✅
- [ ] Commercial Tier 4 (51-100): $15/user ✅
- [ ] Enterprise (100+): Custom pricing ✅

---

**Document Status:** Ready for Review  
**Prepared By:** Jeeves (Master Orchestrator)  
**Date:** April 22, 2026  
**Next Action:** Awaiting approval on protection method and payment processor


---

## Part 9: Square Integration Analysis

### Square for Payment Processing ✅

**Status:** Compatible with SwiftMentor licensing model

**Square Features:**
- ✅ Accept credit/debit cards
- ✅ Digital goods support
- ✅ Invoice generation
- ✅ No monthly fees
- ✅ 2.9% + $0.30 per transaction (standard rate)
- ✅ Next-day deposits available
- ✅ PCI compliant

### Square Integration Options:

#### Option A: Square Online Checkout (RECOMMENDED with Square)

**Best for:** Simple setup with existing Square account

**How it works:**
1. Create payment links in Square Dashboard
2. Square hosts checkout page
3. Customer pays, receives license key via email (manual or automated)
4. Funds deposited to Square account

**Setup Steps:**
1. Log into Square Dashboard
2. Go to Online Checkout → Create Payment Link
3. Set up products (Personal License, Commercial Tiers)
4. Configure automatic email with license key (or send manually)
5. Copy payment link
6. Add to README and app

**Pricing:**
- 2.9% + $0.30 per transaction
- No monthly fees
- No setup fees

**Pros:**
- ✅ You already have Square account
- ✅ Familiar interface
- ✅ No additional account needed
- ✅ Lower fees than Gumroad (2.9% vs 10%)
- ✅ Professional checkout experience
- ✅ GitHub ToS compliant

**Cons:**
- ⚠️ No built-in license key delivery (must be manual or custom)
- ⚠️ Need to email keys manually or set up automation
- ⚠️ Less automated than Gumroad/LemonSqueezy

**Integration Code:**
```markdown
[![Buy Personal License](https://img.shields.io/badge/buy-personal%20license-%233EB9A0?style=for-the-badge&logo=square)](https://square.link/u/YOUR_LINK)
```

---

#### Option B: Square + Zapier Automation

**Best for:** Automated license key delivery with Square

**How it works:**
1. Customer pays via Square payment link
2. Zapier detects payment
3. Zapier sends email with license key
4. Optional: Add customer to spreadsheet/CRM

**Setup:**
1. Create Square payment link
2. Create Zapier account (free tier available)
3. Create Zap: Square → Email
4. Trigger: New Square payment
5. Action: Send email (Gmail, Outlook, etc.)
6. Include license key in email template

**Pricing:**
- Square: 2.9% + $0.30
- Zapier: Free for 100 tasks/month, or $19.99/month for more
- Total: ~2.9% + $0.30 (if under 100 sales/month)

**Pros:**
- ✅ Automated license delivery
- ✅ Uses your existing Square account
- ✅ Lower fees than Gumroad
- ✅ No coding required

**Cons:**
- ⚠️ Requires Zapier account
- ⚠️ Free tier limited to 100 transactions/month
- ⚠️ Slightly more complex setup

---

#### Option C: Square API + Custom Backend

**Best for:** Full control, automated licensing

**How it works:**
1. Build simple web service
2. Integrate Square API for payments
3. Generate and email license keys automatically
4. Track sales and activations

**Requirements:**
- Web server (can use free tier of Vercel, Netlify, etc.)
- Square API integration
- License key generation algorithm
- Email service (SendGrid, Mailgun, etc.)

**Pricing:**
- Square: 2.9% + $0.30
- Server: Free to ~$10/month
- Email: Free tier available
- Total: 2.9% + $0.30 + minimal infrastructure

**Pros:**
- ✅ Full automation
- ✅ Lowest fees
- ✅ Complete control
- ✅ Custom branding

**Cons:**
- ⚠️ Requires development time
- ⚠️ Need to maintain backend
- ⚠️ More complex

---

### Square vs Other Processors Comparison:

| Feature | Square | Gumroad | LemonSqueezy | Stripe |
|---------|--------|---------|--------------|--------|
| **Transaction Fee** | 2.9% + $0.30 | 10% + 2.9% + $0.30 | 5% + $0.50 | 2.9% + $0.30 |
| **Monthly Fee** | $0 | $0 | $0 | $0 |
| **License Keys** | Manual/Zapier | Automatic | Automatic | Custom |
| **Tax Handling** | Basic | Full VAT | Full VAT | You handle |
| **Setup Time** | Minutes | Minutes | ~1 hour | Hours/Days |
| **Best For** | Existing users | Quick start | Software sales | Custom solutions |

**Example Cost Comparison** (on $20 sale):
- **Square:** $0.88 (4.4% effective rate)
- **Gumroad:** $2.29 (11.45% effective rate)
- **LemonSqueezy:** $1.50 (7.5% effective rate)
- **Stripe:** $0.88 (4.4% effective rate)

**Savings with Square vs Gumroad:** $1.41 per $20 sale (71% savings!)

---

### Recommended Square Setup for SwiftMentor:

#### Quick Start (Recommended):

1. **Square Online Checkout Links:**
   - Create product: "SwiftMentor Personal License" - $20
   - Create product: "SwiftMentor Commercial License (1-5 users)" - $175
   - Create product: "SwiftMentor Commercial License (6-20 users)" - $500
   - etc.

2. **Manual License Key Delivery (Start):**
   - Monitor Square dashboard for sales
   - Manually email license keys
   - Track in spreadsheet
   - Time commitment: ~5 minutes per sale

3. **Upgrade Path:**
   - Add Zapier automation when sales volume justifies
   - Or build custom backend later

#### Implementation Steps:

**Step 1: Create Square Products**
```
1. Log into Square Dashboard
2. Items → Create Item
3. Name: SwiftMentor Personal License
4. Price: $20.00
5. Description: 30-day trial, then perpetual personal license
6. Repeat for commercial tiers
```

**Step 2: Generate Payment Links**
```
1. Go to Online Checkout → Payment Links
2. Create Link for each product
3. Copy URLs
4. Test purchase flow
```

**Step 3: Set Up License Key System**
```
Option A - Manual:
- Create spreadsheet with license keys
- Pre-generate 100 keys
- Email manually when sale occurs

Option B - Zapier:
- Create Zapier account
- Connect Square → Email
- Set up email template with key
- Test automation
```

**Step 4: Add to GitHub**
```markdown
## Purchase License

### Personal License
- **30-day free trial** included
- **$20** - One-time purchase
- [Buy Now with Square](https://square.link/u/YOUR_LINK)

### Commercial License
- Volume discounts available
- [View Commercial Options](LINK_TO_PAGE)
```

---

### Square-Specific Considerations:

#### ✅ Advantages:
1. **You already have account** - No new setup
2. **Lower fees** - 2.9% vs 10% (Gumroad)
3. **Trusted brand** - Customers recognize Square
4. **Fast setup** - Payment links in minutes
5. **No monthly fees** - Pay only when you sell
6. **Next-day deposits** - Fast access to funds

#### ⚠️ Limitations:
1. **No built-in license keys** - Must handle manually or with Zapier
2. **No tiered pricing automation** - Must create separate products
3. **Basic digital delivery** - Not as polished as LemonSqueezy

#### 🔒 Security:
- Square is PCI DSS Level 1 certified
- Handles all card data securely
- No sensitive data stored on GitHub
- Compliant with payment regulations

---

### Updated Recommendation with Square:

**For SwiftMentor, given you have Square:**

1. **Immediate (Day 1):**
   - Create Square payment links
   - Set up manual license key delivery
   - Add purchase links to README
   - Replace MIT license with LICENSE.md

2. **Short-term (Week 1-2):**
   - Set up Zapier automation (if sales volume > 5/week)
   - Create license key generation script (keep OFF GitHub)
   - Test complete flow

3. **Long-term (Month 2+):**
   - If sales exceed 50/month, consider LemonSqueezy for automation
   - Or build custom backend with Square API
   - Evaluate based on revenue vs time investment

**Cost Efficiency:**
- Square: 2.9% + $0.30 = ~$0.88 on $20 sale
- vs Gumroad: 10% + fees = ~$2.29 on $20 sale
- **Savings: $1.41 per sale (71% less fees!)**

**At 100 sales/month:**
- Square: ~$88 in fees
- Gumroad: ~$229 in fees
- **Monthly savings: $141**
- **Annual savings: $1,692**

---

## Part 10: Updated Action Items with Square

### ✅ Approved (Ready to Implement):

**License:**
- [x] Commercial license drafted (LICENSE.md)
- [ ] Replace MIT license on GitHub
- [ ] Add license validation to app (pending protection method choice)

**Payment Processing:**
- [x] Square account exists
- [ ] Create payment links in Square Dashboard
- [ ] Test payment flow
- [ ] Set up manual license key delivery system
- [ ] (Optional) Set up Zapier automation

**Copy Protection:**
- [ ] Choose method (Option A recommended: License Key Validation)
- [ ] Implement trial period tracking
- [ ] Implement license key validation
- [ ] Create developer license key (unlimited)
- [ ] Test complete flow

**Documentation:**
- [ ] Update README with pricing info
- [ ] Add Square payment badges/links
- [ ] Create LICENSE.md page
- [ ] Add FAQ section
- [ ] Document trial period clearly

**GitHub Cleanup:**
- [ ] Remove MIT license file
- [ ] Add LICENSE.md (commercial)
- [ ] Add sensitive files to .gitignore
- [ ] Create private repo for key generator
- [ ] Verify no sensitive data in public repo

---

## Questions Requiring Your Approval:

### 1. Copy Protection Method:
- [ ] **Option A:** Simple license key validation ✅ **RECOMMENDED**
- [ ] Option B: Hardware-bound licensing
- [ ] Option C: Time-limited trial with feature lock
- [ ] Option D: Online license server

**Why Option A is recommended:**
- Easiest to implement (1-2 days)
- Works offline
- User-friendly
- GitHub ToS compliant
- You can generate unlimited keys for yourself
- Can be automated with Square + Zapier

---

### 2. Payment Setup with Square:
- [x] Square account exists ✅
- [ ] Create payment links (you can do this now)
- [ ] Manual license delivery to start
- [ ] Add Zapier automation later (when needed)

**Recommended Square Products:**
1. SwiftMentor Personal License - $20
2. SwiftMentor Commercial (1-5 users) - $175
3. SwiftMentor Commercial (6-20 users) - $500
4. SwiftMentor Commercial (21-50 users) - $1,000
5. SwiftMentor Commercial (51-100 users) - $1,500

---

### 3. License Text Approval:
- [x] Commercial license drafted ✅
- [ ] Review and approve LICENSE.md
- [ ] Replace MIT license
- [ ] Update copyright year if needed

---

### 4. Implementation Priority:
1. **Critical (This Session):**
   - Replace MIT with commercial license ✅ (ready to commit)
   - Choose copy protection method
   - Set up Square payment links

2. **High (Next Session):**
   - Implement license validation in app
   - Add trial period tracking
   - Test complete purchase flow

3. **Medium (Following Sessions):**
   - Add Zapier automation
   - Enhance copy protection
   - Add more learning paths (Issue #3)

4. **Low (Future):**
   - AI Assistant backend (Issue #5)
   - Other enhancements

---

**Status:** Awaiting your approval on:
1. ✅ Copy protection method (recommending Option A)
2. ✅ License text (LICENSE.md drafted above)
3. ⏳ Square payment link creation (you can do this anytime)

**Once approved, I will:**
- Replace MIT license with LICENSE.md
- Implement license validation code
- Add trial period enforcement
- Update README with purchase info
- Remove sensitive code from public repo

---

**Prepared By:** Jeeves (Master Orchestrator)  
**Date:** April 22, 2026  
**Status:** Ready for Your Approval
