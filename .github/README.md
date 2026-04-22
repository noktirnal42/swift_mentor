# GitHub Community Files

This directory contains configuration and templates for the SwiftMentor project.

## 📁 File Structure

```
.github/
├── ISSUE_TEMPLATES/
│   ├── bug_report.md        # Template for bug reports
│   ├── feature_request.md   # Template for feature requests
│   ├── lesson_content.md    # Template for lesson/content additions
│   ├── code_quality.md      # Template for code quality improvements
│   └── general_issue.md     # Template for general issues
├── workflows/
│   └── build.yml            # CI/CD workflow for builds
├── CODEOWNERS               # Code ownership rules
├── CONTRIBUTING.md          # Contribution guidelines (root)
├── PULL_REQUEST_TEMPLATE.md # Template for pull requests
├── dependabot.yml           # Dependabot configuration
└── README.md                # This file
```

## 🎯 Issue Templates

When creating a new issue, please use the appropriate template:

- **Bug Report**: Use when something isn't working correctly
- **Feature Request**: Use when suggesting new functionality
- **Lesson Content**: Use when adding or updating lesson content
- **Code Quality**: Use for refactoring suggestions or technical debt
- **General Issue**: Use for questions or discussions

## 🏷️ Labels

The project uses the following labels to organize issues:

### Type Labels
- `bug` - Something isn't working
- `enhancement` - New feature or request
- `content` - Lesson or learning path content
- `documentation` - Documentation improvements
- `dependencies` - Dependency updates

### Priority Labels
- `priority: high` - High priority
- `priority: medium` - Medium priority
- `priority: low` - Low priority

### Status Labels
- `good first issue` - Good for newcomers
- `help wanted` - Extra attention is needed
- `in progress` - Someone is working on it

## 🔄 Workflows

### Build & Test

The `build.yml` workflow runs on every push and PR:

- ✅ Generates project with XcodeGen
- ✅ Builds the app in Debug configuration
- ✅ Runs tests (when available)
- ✅ Verifies no build errors

## 📋 Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for detailed contribution guidelines.

Quick links:
- [Issue Templates](ISSUE_TEMPLATES/)
- [Pull Request Template](PULL_REQUEST_TEMPLATE.md)
- [Code of Conduct](../CODE_OF_CONDUCT.md)

## 🤝 Code Review

All contributions are reviewed before merging. Reviewers look for:

1. Code quality and adherence to style guidelines
2. Proper testing (manual or automated)
3. Clear commit messages
4. Updated documentation
5. No breaking changes (unless intentional and documented)

## 📞 Support

- **Questions?** Create a [General Issue](ISSUE_TEMPLATES/general_issue.md)
- **Bugs?** Create a [Bug Report](ISSUE_TEMPLATES/bug_report.md)
- **Features?** Create a [Feature Request](ISSUE_TEMPLATES/feature_request.md)
