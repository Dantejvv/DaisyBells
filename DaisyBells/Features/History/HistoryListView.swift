import SwiftUI

/// Chronological list of completed workouts
struct HistoryListView: View {
    @State private var viewModel: HistoryListViewModel
    @State private var deleteConfig: ConfirmationDialogConfig?
    @State private var clearAllConfig: ConfirmationDialogConfig?

    init(viewModel: HistoryListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Grouped Workouts

    private var groupedWorkouts: [(key: String, workouts: [SchemaV1.Workout])] {
        let calendar = Calendar.current
        let now = Date()

        var groups: [String: [SchemaV1.Workout]] = [:]

        for workout in viewModel.workouts {
            let date = workout.completedAt ?? workout.startedAt
            let key: String

            if calendar.isDateInToday(date) {
                key = "Today"
            } else if calendar.isDateInYesterday(date) {
                key = "Yesterday"
            } else if let daysAgo = calendar.dateComponents([.day], from: date, to: now).day,
                      daysAgo < 7 {
                key = "This Week"
            } else if let weeksAgo = calendar.dateComponents([.weekOfYear], from: date, to: now).weekOfYear,
                      weeksAgo < 4 {
                key = "This Month"
            } else {
                key = date.monthYearFormat
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

                let date1 = first.value.first.flatMap { $0.completedAt ?? $0.startedAt } ?? .distantPast
                let date2 = second.value.first.flatMap { $0.completedAt ?? $0.startedAt } ?? .distantPast
                return date1 > date2
            }
            .map {
                (
                    key: $0.key,
                    workouts: $0.value.sorted {
                        ($0.completedAt ?? $0.startedAt) > ($1.completedAt ?? $1.startedAt)
                    }
                )
            }
    }

    // MARK: - View

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingSpinnerView(message: "Loading history...")
            } else if viewModel.workouts.isEmpty {
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
                                Button {
                                    viewModel.selectWorkout(workout)
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
                                            Task { await viewModel.deleteWorkout(workout) }
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
            if !viewModel.workouts.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            clearAllConfig = ConfirmationDialogConfig(
                                title: "Clear All History?",
                                message: "This will permanently delete all your workout history. This action cannot be undone.",
                                confirmTitle: "Clear All"
                            ) {
                                Task { await viewModel.clearAllHistory() }
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
        .errorAlert(Binding(
            get: { viewModel.errorMessage },
            set: { viewModel.errorMessage = $0 }
        ))
        .task { await viewModel.loadWorkouts() }
    }
}

// MARK: - Row

private struct WorkoutHistoryRow: View {
    let workout: SchemaV1.Workout

    private var workoutName: String {
        workout.fromTemplate?.name ?? "Workout"
    }

    private var completionDate: Date {
        workout.completedAt ?? workout.startedAt
    }

    private var duration: TimeInterval {
        guard let completedAt = workout.completedAt else { return 0 }
        return completedAt.timeIntervalSince(workout.startedAt)
    }

    private var totalSets: Int {
        workout.loggedExercises.reduce(0) { $0 + $1.sets.count }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(workoutName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Spacer()

                Text(duration.durationString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                Text(formattedDate)
                Text("•")
                Text("\(workout.loggedExercises.count) exercises")
                Text("•")
                Text("\(totalSets) sets")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var formattedDate: String {
        let calendar = Calendar.current

        if calendar.isDateInToday(completionDate) ||
           calendar.isDateInYesterday(completionDate) {
            return completionDate.timeFormat
        } else {
            return completionDate.workoutListFormat
        }
    }
}
