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

    /// Formatted for workout list display: "Mon, Jan 15"
    var workoutListFormat: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: self)
    }

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

    /// Formatted for analytics: "Jan 2024"
    var monthYearFormat: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: self)
    }

    /// Formatted short date: "Jan 15"
    var shortDateFormat: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }

    // MARK: - Date Calculations

    /// Start of the current week (Sunday)
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }

    /// Start of the current month
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }

    /// Start of the current day
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// End of the current day
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }
}
