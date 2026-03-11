import Foundation

@MainActor @Observable
final class HistoryCalendarViewModel {
    // MARK: - State

    private(set) var displayedMonth: Date = Date()
    private(set) var workoutDays: Set<Date> = []
    private(set) var isLoading = false
    private(set) var isCollapsed = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let workoutService: WorkoutServiceProtocol
    private let calendar = Calendar.current

    // MARK: - Init

    init(workoutService: WorkoutServiceProtocol) {
        self.workoutService = workoutService
    }

    // MARK: - Computed

    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    var weekdayLabels: [String] {
        let symbols = DateFormatter().shortWeekdaySymbols ?? []
        let firstWeekday = calendar.firstWeekday - 1
        return Array(symbols[firstWeekday...]) + Array(symbols[..<firstWeekday])
    }

    var daysInMonth: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) else {
            return []
        }
        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth)
        }
    }

    var prefixPadding: Int {
        guard let firstOfMonth = daysInMonth.first else { return 0 }
        let weekday = calendar.component(.weekday, from: firstOfMonth)
        return (weekday - calendar.firstWeekday + 7) % 7
    }

    var currentWeekDays: [Date] {
        let startOfWeek: Date = {
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: displayedMonth)
            return calendar.date(from: components) ?? displayedMonth
        }()
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startOfWeek)
        }
    }

    // MARK: - Intents

    func loadWorkoutDays() async {
        isLoading = true
        errorMessage = nil
        do {
            let completed = try await workoutService.fetchCompleted()
            workoutDays = Set(completed.compactMap { workout in
                (workout.completedAt ?? workout.startedAt).startOfDay
            })
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func goToPreviousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }

    func goToNextMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }

    func goToToday() {
        displayedMonth = Date()
    }

    func toggleCollapsed() {
        isCollapsed.toggle()
    }

    // MARK: - Helpers

    func hasWorkout(on date: Date) -> Bool {
        workoutDays.contains(date.startOfDay)
    }

    func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    func isInDisplayedMonth(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month)
    }
}
