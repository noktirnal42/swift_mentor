---
name: 📚 New Lesson Content
about: Add new lessons, learning paths, or update existing content
title: '[CONTENT] '
labels: enhancement, content
assignees: ''

---

## Content Type

<!-- Select the type of content contribution -->

- [ ] New Learning Path
- [ ] New Lesson
- [ ] Update Existing Lesson
- [ ] Correction/Fix in Existing Content
- [ ] Translation/Localization

## Learning Path Details (if applicable)

<!-- If adding a new learning path, provide details -->

**Path Title:** 
**Path ID:** (kebab-case, e.g., `visionos-essentials`)
**Number of Lessons:** 
**Difficulty Level:** [Beginner | Intermediate | Advanced]
**Description:** 

## Lesson Details (if applicable)

<!-- If adding or updating lessons, provide details -->

**Lesson Title:** 
**Lesson ID:** (kebab-case, e.g., `swift-fundamentals-1`)
**Parent Path:** 
**Lesson Order:** 
**Description:** 

## Content Schema

<!-- Ensure your content follows the schema in CONTRIBUTING.md -->
<!-- Include JSON snippet if adding new lesson -->

```json
{
  "id": "your-lesson-id",
  "pathId": "your-path-id",
  "title": "Lesson Title",
  "description": "Brief description",
  "order": 1,
  "type": "lesson",
  "sections": [
    {
      "title": "Section Title",
      "content": "Content here",
      "type": "theory"
    }
  ]
}
```

## Changes Made

<!-- List all files added, modified, or deleted -->

- [ ] Added lesson JSON file: `SwiftMentor/Resources/Lessons/your-path-N.json`
- [ ] Updated `SwiftMentor/Resources/LearningPaths/paths.json`
- [ ] Added fallback in `ContentService.swift`
- [ ] Ran `xcodegen generate` to regenerate project

## Testing

<!-- Describe how you tested the changes -->

- [ ] App builds without errors
- [ ] New lesson loads correctly
- [ ] All sections display properly
- [ ] Code examples render correctly
- [ ] Quiz questions work (if applicable)
- [ ] Progress tracking works (if applicable)

## Screenshots (if applicable)

<!-- Add screenshots showing the new content in the app -->

## Additional Notes

<!-- Any other information that would be helpful to reviewers -->
