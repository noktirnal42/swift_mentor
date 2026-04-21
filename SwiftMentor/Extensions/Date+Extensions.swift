import Foundation

extension Date {
    /// Returns a localized relative date string (e.g., "2 hours ago", "yesterday")
    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}