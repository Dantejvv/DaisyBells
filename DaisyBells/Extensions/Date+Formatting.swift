import Foundation

extension Date {

    // MARK: - Relative Formatting

    /// Returns relative description like "Today", "Yesterday", "2 days ago"
    var relativeDescription: String {
        let calendar = Calendar.current

        if calendar.isDateInToday(self) {
            return "Today"
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday"
        } else {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return formatter.localizedString(for: self, relativeTo: Date())
        }
    }

    // MARK: - Workout Display

    /// Formatted for workout detail: "Monday, January 15, 2024"
    var workoutDetailFormat: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    /// Formatted time only: "2:30 PM"
    var timeFormat: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    /// Formatted for history day headers: "Monday, February 17"
    var dayHeaderFormat: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: self)
    }

    // MARK: - Date Calculations

    /// Start of the current day
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

}
