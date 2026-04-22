# Security Policy

## Reporting a Vulnerability

**Please do NOT report security vulnerabilities through public GitHub issues.**

Instead, please report them by:

1. **Email**: Contact @noktirnal42 via GitHub
2. **GitHub Security Advisories**: Use the private vulnerability reporting feature

### Response Time

- **Acknowledgment**: Within 48 hours
- **Status Update**: Within 7 days
- **Resolution**: Critical issues within 7 days

### What to Include

- Description of the vulnerability
- Reproduction steps
- Potential impact
- Environment details (macOS, Xcode, App version)
- Proof-of-concept (if available)

### What NOT to Do

- ❌ Do not create public GitHub issues for security vulnerabilities
- ❌ Do not disclose the vulnerability publicly before we've had time to fix it
- ❌ Do not access or modify user data without permission

### Our Commitment

- We will acknowledge your report within 48 hours
- We will keep you informed of our progress
- We will credit you (with permission) when the issue is resolved
- We will not take legal action against good-faith security research

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.2.x   | ✅ Yes             |
| < 1.0   | ❌ No              |

## Security Measures

### Currently Implemented

- ✅ Secret scanning
- ✅ Dependabot alerts
- ✅ Security policy
- ✅ Code signing
- ✅ Notarization

### Planned

- CodeQL scanning
- Regular security audits
- Enhanced sandboxing

## For Contributors

When contributing code:

1. **Never commit secrets** (API keys, passwords, tokens)
2. **Validate all inputs** from users
3. **Keep dependencies updated**
4. **Follow secure coding practices**

See [SECURITY.md](../SECURITY.md) for detailed guidelines.

---

**Thank you for helping keep SwiftMentor and our users safe!**
