# Security Policy

## Supported Versions

We release patches for security vulnerabilities regularly. Supported versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.2.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take the security of SwiftMentor seriously. If you believe you've found a security vulnerability, please follow the guidelines below.

### How to Report

**Please do NOT report security vulnerabilities through public GitHub issues.**

Instead, please report them via email to: **noktirnal42@github** (or create a draft security issue on GitHub)

You should receive a response within **48 hours** acknowledging your report.

### What to Include

To help us triage your report quickly, please include:

1. **Description of the vulnerability**
   - Type of issue (e.g., buffer overflow, SQL injection, cross-site scripting, etc.)
   - Full paths of source file(s) related to the issue
   - Location of the affected source code (tag/branch/commit or direct URL)

2. **Reproduction steps**
   - Any special configuration needed to reproduce the issue
   - Step-by-step instructions to reproduce the issue
   - Proof-of-concept or exploit code (if possible)

3. **Impact**
   - Potential impact of the vulnerability
   - Possible attack scenarios

4. **Environment**
   - macOS version
   - Xcode version
   - App version

### What to Expect

1. **Initial Response**: Within 48 hours, you'll receive acknowledgment of your report
2. **Status Updates**: We'll provide updates every 7 days on the status
3. **Resolution Timeline**: We aim to resolve critical issues within 7 days
4. **Disclosure**: We'll coordinate public disclosure with you

### Security Research

We welcome security research that:
- Helps us understand and fix security issues
- Follows responsible disclosure practices
- Respects user privacy and data

We ask that researchers:
- Make a good faith effort to avoid privacy violations
- Avoid destruction of data
- Not degrade the user experience
- Keep information confidential until we've resolved the issue

## Security Best Practices for Contributors

### Code Security

When contributing to SwiftMentor, please follow these security guidelines:

1. **Never commit secrets**
   - API keys
   - Passwords
   - Tokens
   - Private keys
   - Certificates

2. **Input Validation**
   - Validate all user inputs
   - Sanitize data before use
   - Use parameterized queries (where applicable)

3. **Dependencies**
   - Keep dependencies up to date
   - Review security advisories
   - Use trusted sources only

4. **Code Execution**
   - The app executes Swift code - ensure proper sandboxing
   - Validate code before execution
   - Implement timeout mechanisms

5. **Data Protection**
   - Encrypt sensitive data at rest
   - Use secure storage mechanisms
   - Clear sensitive data from memory

### Reporting Security Issues in Code Reviews

When reviewing code, watch for:
- Hardcoded credentials
- Insecure data storage
- Missing input validation
- Unchecked user input
- Insecure network communications
- Missing error handling

## Security Features

### Current Security Measures

- [ ] Code signing with Developer ID
- [ ] Hardened Runtime enabled
- [x] Notarization for distribution
- [x] Secret scanning enabled
- [x] Dependabot alerts enabled
- [x] Security policy documented
- [ ] Code scanning with CodeQL
- [ ] Regular security audits

### Future Security Improvements

We plan to implement:
- Regular security audits
- Automated security scanning in CI/CD
- Sandboxed code execution
- Enhanced data encryption
- Security-focused documentation

## Acknowledgments

We appreciate the work of security researchers and will acknowledge contributors who report valid security issues (with permission).

## Legal

This security policy does not create any legal obligations. It is intended as a guideline for reporting and handling security issues.

---

**Last Updated:** April 22, 2026  
**Version:** 1.0
