import SwiftUI

/// Chronological list of completed workouts
struct HistoryListView: View {
    @State private var workouts = MockWorkoutHistory.workouts
    @State private var deleteConfig: ConfirmationDialogConfig?
    @State private var clearAllConfig: ConfirmationDialogConfig?

    // MARK: - Grouped Workouts

    private var groupedWorkouts: [(key: String, workouts: [MockCompletedWorkout])] {
        let calendar = Calendar.current
        let now = Date()

        var groups: [String: [MockCompletedWorkout]] = [:]

        for workout in workouts {
            let key: String

            if calendar.isDateInToday(workout.completedAt) {
                key = "Today"
            } else if calendar.isDateInYesterday(workout.completedAt) {
                key = "Yesterday"
            } else if let daysAgo = calendar.dateComponents([.day], from: workout.completedAt, to: now).day,
                      daysAgo < 7 {
                key = "This Week"
            } else if let weeksAgo = calendar.dateComponents([.weekOfYear], from: workout.completedAt, to: now).weekOfYear,
                      weeksAgo < 4 {
                key = "This Month"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                key = formatter.string(from: workout.completedAt)
            }

            groups[key, default: []].append(workout)
        }

        let sectionOrder = ["Today", "Yesterday", "This Week", "This Month"]

        return groups
            .sorted { first, second in
                let index1 = sectionOrder.firstIndex(of: first.key) ?? Int.max
                let index2 = sectionOrder.firstIndex(of: second.key) ?? Int.max

                if index1 != index2 {
                    return index1 < index2
                }

                // Month sections sorted by most recent workout
                return (first.value.first?.completedAt ?? .distantPast) >
                       (second.value.first?.completedAt ?? .distantPast)
            }
            .map {
                (
                    key: $0.key,
                    workouts: $0.value.sorted { $0.completedAt > $1.completedAt }
                )
            }
    }

    // MARK: - View

    var body: some View {
        Group {
            if workouts.isEmpty {
                EmptyStateView(
                    systemImage: "calendar",
                    title: "No Workout History",
                    message: "Complete a workout to see it here."
                )
            } else {
                List {
                    ForEach(groupedWorkouts, id: \.key) { section in
                        Section(section.key) {
                            ForEach(section.workouts) { workout in
                                NavigationLink {
                                    CompletedWorkoutDetailView(workout: workout)
                                } label: {
                                    WorkoutHistoryRow(workout: workout)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button("Delete", role: .destructive) {
                                        deleteConfig = ConfirmationDialogConfig(
                                            title: "Delete Workout?",
                                            message: "This workout will be permanently deleted from your history.",
                                            confirmTitle: "Delete"
                                        ) {
                                            withAnimation {
                                                workouts.removeAll { $0.id == workout.id }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("History")
        .toolbar {
            if !workouts.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            clearAllConfig = ConfirmationDialogConfig(
                                title: "Clear All History?",
                                message: "This will permanently delete all your workout history. This action cannot be undone.",
                                confirmTitle: "Clear All"
                            ) {
                                withAnimation {
                                    workouts.removeAll()
                                }
                            }
                        } label: {
                            Label("Clear All History", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .confirmationDialog($deleteConfig)
        .confirmationDialog($clearAllConfig)
    }
}

// MARK: - Row

private struct WorkoutHistoryRow: View {
    let workout: MockCompletedWorkout

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(workout.name)
                    .font(.body)
                    .fontWeight(.medium)

                Spacer()

                Text(formattedDuration)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                Text(formattedDate)
                Text("•")
                Text("\(workout.exerciseCount) exercises")
                Text("•")
                Text("\(workout.totalSets) sets")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(workout.completedAt) ||
           calendar.isDateInYesterday(workout.completedAt) {
            formatter.dateFormat = "h:mm a"
        } else {
            formatter.dateFormat = "E, MMM d"
        }

        return formatter.string(from: workout.completedAt)
    }

    private var formattedDuration: String {
        let hours = Int(workout.duration) / 3600
        let minutes = (Int(workout.duration) % 3600) / 60

        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}

// MARK: - Preview

#Preview("With History") {
    NavigationStack {
        HistoryListView()
    }
}
