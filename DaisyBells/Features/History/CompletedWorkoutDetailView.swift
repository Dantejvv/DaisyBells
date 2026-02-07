import SwiftUI

/// Read-only view of a completed workout, matching ActiveWorkoutView layout
struct CompletedWorkoutDetailView: View {
    @State private var viewModel: CompletedWorkoutDetailViewModel
    @State private var deleteConfig: ConfirmationDialogConfig?

    init(viewModel: CompletedWorkoutDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingSpinnerView(message: "Loading workout...")
            } else if let workout = viewModel.workout {
                workoutContent(workout)
            }
        }
        .errorAlert(Binding(
            get: { viewModel.errorMessage },
            set: { viewModel.errorMessage = $0 }
        ))
        .task { await viewModel.loadWorkout() }
    }

    @ViewBuilder
    private func workoutContent(_ workout: SchemaV1.Workout) -> some View {
        List {
            // MARK: - Header Section
            Section {
                // Title
                Text(workout.fromTemplate?.name ?? "Workout")
                    .font(.title2.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .center)

                // Date and Duration
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        if let completedAt = workout.completedAt {
                            Text(completedAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        Text("Completed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(viewModel.duration.timerString)
                            .font(.system(.title, design: .monospaced))
                            .fontWeight(.medium)
                        Text("Duration")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Notes
                if let notes = workout.notes, !notes.isEmpty {
                    Text(notes)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No notes")
                        .foregroundStyle(.tertiary)
                        .italic()
                }
            }

            // MARK: - Exercise Sections
            ForEach(viewModel.exercises) { exercise in
                Section {
                    let sortedSets = exercise.sets.sorted { $0.order < $1.order }
                    ForEach(Array(sortedSets.enumerated()), id: \.element.id) { index, set in
                        LoggedSetDisplayView(
                            exerciseType: exercise.exercise?.type ?? .weightAndReps,
                            setNumber: index + 1,
                            weight: set.weight,
                            reps: set.reps,
                            bodyweightModifier: set.bodyweightModifier,
                            time: set.time,
                            distance: set.distance,
                            notes: set.notes ?? ""
                        )
                    }
                } header: {
                    exerciseHeader(for: exercise)
                }
            }

            // MARK: - Delete Section
            Section {
                Button(role: .destructive) {
                    deleteConfig = ConfirmationDialogConfig(
                        title: "Delete Workout?",
                        message: "This workout will be permanently deleted from your history.",
                        confirmTitle: "Delete"
                    ) {
                        Task { await viewModel.deleteWorkout() }
                    }
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "trash")
                        Text("Delete Workout")
                        Spacer()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(0)
        .contentMargins(.top, 0, for: .scrollContent)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog($deleteConfig)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func exerciseHeader(for exercise: SchemaV1.LoggedExercise) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.exercise?.name ?? "Exercise")
                    .font(.headline)
                    .textCase(nil)
                    .foregroundStyle(Color(.label))
                Text(exercise.exercise?.type.displayName ?? "")
                    .font(.caption)
                    .textCase(nil)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

/// Read-only display of a logged set, matching LoggedSetEditorView layout
private struct LoggedSetDisplayView: View {
    let exerciseType: ExerciseType
    let setNumber: Int
    let weight: Double?
    let reps: Int?
    let bodyweightModifier: Double?
    let time: TimeInterval?
    let distance: Double?
    let notes: String

    var body: some View {
        HStack(spacing: 16) {
            // Set number indicator
            Text("\(setNumber)")
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            // Dynamic display based on exercise type
            switch exerciseType {
            case .weightAndReps:
                valueDisplay(value: formatWeight(weight), label: "lbs")
                valueDisplay(value: formatReps(reps), label: "reps")

            case .bodyweightAndReps:
                valueDisplay(value: formatBodyweightModifier(bodyweightModifier), label: "+/- lbs")
                valueDisplay(value: formatReps(reps), label: "reps")

            case .reps:
                valueDisplay(value: formatReps(reps), label: "reps")

            case .time:
                valueDisplay(value: formatTime(time), label: "min")

            case .distanceAndTime:
                valueDisplay(value: formatDistance(distance), label: "mi")
                valueDisplay(value: formatTime(time), label: "min")

            case .weightAndTime:
                valueDisplay(value: formatWeight(weight), label: "lbs")
                valueDisplay(value: formatTime(time), label: "min")
            }

            Spacer()

            // Notes display
            if !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }

    private func valueDisplay(value: String, label: String) -> some View {
        VStack(alignment: .center, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .frame(width: label == "+/- lbs" ? 50 : 40)
                .padding(6)
                .background(Color(.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    // MARK: - Formatters

    private func formatWeight(_ weight: Double?) -> String {
        guard let weight else { return "—" }
        return "\(Int(weight))"
    }

    private func formatReps(_ reps: Int?) -> String {
        guard let reps else { return "—" }
        return "\(reps)"
    }

    private func formatBodyweightModifier(_ modifier: Double?) -> String {
        guard let modifier else { return "BW" }
        if modifier > 0 {
            return "+\(Int(modifier))"
        } else if modifier < 0 {
            return "\(Int(modifier))"
        } else {
            return "BW"
        }
    }

    private func formatTime(_ time: TimeInterval?) -> String {
        guard let time else { return "—" }
        let minutes = time / 60
        return String(format: "%.1f", minutes)
    }

    private func formatDistance(_ distance: Double?) -> String {
        guard let distance else { return "—" }
        return String(format: "%.2f", distance)
    }
}
