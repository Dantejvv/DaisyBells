import SwiftUI
import SwiftData

@MainActor
struct HistoryListView: View {
    @State var viewModel: HistoryListViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingSpinnerView()
            } else if viewModel.isEmpty {
                EmptyStateView(
                    icon: "clock",
                    title: "No Workout History",
                    message: "Completed workouts will appear here."
                )
            } else {
                workoutList
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
.task { await viewModel.loadWorkouts() }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if !viewModel.workouts.isEmpty {
                    Button {
                        viewModel.showClearAllConfirmation = true
                    } label: {
                        Text("Clear All")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.red)
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    // filter/calendar action — TBD
                } label: {
                    Image(systemName: "calendar")
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .destructiveConfirmation(
            title: "Clear All History",
            message: "This will permanently delete all completed workouts. This action cannot be undone.",
            isPresented: $viewModel.showClearAllConfirmation,
            onConfirm: {
                Task { await viewModel.clearAllHistory() }
            }
        )
        .errorAlert(errorMessage: $viewModel.errorMessage)
        .background(Color.bgPrimary)
        .preferredColorScheme(.dark)
    }

    // MARK: - Workout List

    private var workoutList: some View {
        List {
            ForEach(viewModel.groupedWorkouts, id: \.0) { header, workouts in
                Section {
                    ForEach(workouts, id: \.id) { workout in
                        workoutRow(workout)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    Task { await viewModel.deleteWorkout(workout) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                } header: {
                    Text(header)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.textSecondary)
                        .textCase(nil)
                }
            }
        }
        .listStyle(.insetGrouped)
        .contentMargins(.top, .spacingXs)
        .scrollContentBackground(.hidden)
        .background(Color.bgPrimary)
    }

    // MARK: - Workout Row

    private func workoutRow(_ workout: SchemaV1.Workout) -> some View {
        Button {
            viewModel.selectWorkout(workout)
        } label: {
            HStack(spacing: .spacingMd) {
                // Leading: green checkmark icon
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.success)
                    .frame(width: 32, height: 32)
                    .background(Color.successBg)
                    .clipShape(RoundedRectangle(cornerRadius: .radiusMd))

                // Center: workout info
                VStack(alignment: .leading, spacing: .spacing2xs) {
                    Text(workout.fromTemplate?.name ?? "Workout")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)

                    Text(detailLine(for: workout))
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                // Trailing: time + chevron
                VStack(alignment: .trailing, spacing: .spacing2xs) {
                    Text((workout.completedAt ?? workout.startedAt).timeFormat)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textTertiary)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)
                }
            }
            .padding(.vertical, .spacingXs)
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.bgCard)
    }

    // MARK: - Detail Line

    private func detailLine(for workout: SchemaV1.Workout) -> String {
        let exerciseCount = workout.loggedExercises.count
        let duration = viewModel.duration(for: workout).durationString
        let volume = viewModel.totalVolume(for: workout).volumeString(units: viewModel.units)
        return "\(exerciseCount) exercise\(exerciseCount == 1 ? "" : "s") \u{00B7} \(duration) \u{00B7} \(volume)"
    }
}
