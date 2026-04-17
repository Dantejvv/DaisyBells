import SwiftUI
import SwiftData

@MainActor
struct CompletedWorkoutDetailView: View {
    @State var viewModel: CompletedWorkoutDetailViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingSpinnerView()
            } else if let workout = viewModel.workout {
                workoutContent(workout)
            } else {
                Color.clear
            }
        }
        .task { await viewModel.loadWorkout() }
        .navigationTitle(viewModel.workout?.fromTemplate?.name ?? "Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    viewModel.showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(Color.destructive)
                }
            }
        }
        .destructiveConfirmation(
            title: "Delete Workout",
            message: "This will permanently delete this workout and all its data. This action cannot be undone.",
            isPresented: $viewModel.showDeleteConfirmation,
            onConfirm: {
                Task { await viewModel.deleteWorkout() }
            }
        )
        .errorAlert(errorMessage: $viewModel.errorMessage)
        .background(Color.bgPrimary)
    }

    // MARK: - Workout Content

    private func workoutContent(_ workout: SchemaV1.Workout) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                summaryCard(workout)

                ForEach(viewModel.exercises, id: \.id) { loggedExercise in
                    exerciseCard(loggedExercise)
                }
            }
            .padding(.horizontal, .spacingBase)
            .padding(.bottom, .spacing4xl)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Summary Card

    private func summaryCard(_ workout: SchemaV1.Workout) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Date
            Text((workout.completedAt ?? workout.startedAt).workoutDetailFormat)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            // Duration
            Text(viewModel.duration.workoutDurationString)
                .font(.system(size: 13))
                .foregroundStyle(Color.textSecondary)
                .padding(.top, .spacing2xs)

            Divider()
                .background(Color.borderSubtle)
                .padding(.top, 10)

            // Stats row
            HStack(spacing: .spacingXl) {
                summaryStatItem(label: "Exercises", value: "\(viewModel.exercises.count)")
                summaryStatItem(label: "Sets", value: "\(viewModel.totalSets)")
                summaryStatItem(label: "Volume", value: viewModel.totalVolume.volumeString(units: viewModel.units))
            }
            .padding(.top, 10)

            // Template notes
            if viewModel.hasTemplate {
                notesSection(workout)
            }
        }
        .padding(14)
        .padding(.horizontal, 2)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: .radiusLg))
        .overlay(
            RoundedRectangle(cornerRadius: .radiusLg)
                .stroke(Color.borderSubtle, lineWidth: 1)
        )
    }

    private func summaryStatItem(label: String, value: String) -> some View {
        VStack(spacing: .spacing2xs) {
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.textTertiary)
        }
    }

    private func notesSection(_ workout: SchemaV1.Workout) -> some View {
        let currentNotes = workout.fromTemplate?.notes ?? ""
        return VStack(alignment: .leading, spacing: .spacingSm) {
            Divider()
                .background(Color.borderSubtle)
                .padding(.top, 10)

            TextField(
                "Notes",
                text: Binding(
                    get: { currentNotes },
                    set: { newValue in
                        Task { await viewModel.updateNotes(newValue) }
                    }
                ),
                axis: .vertical
            )
            .font(.system(size: 13))
            .foregroundStyle(Color.textSecondary)
            .lineLimit(1...5)
        }
    }

    // MARK: - Exercise Card

    private func exerciseCard(_ loggedExercise: SchemaV1.LoggedExercise) -> some View {
        let exercise = loggedExercise.exercise
        let exerciseType = exercise?.type ?? .weightAndReps
        let sets = loggedExercise.sets.sorted { $0.order < $1.order }
        let weightUnit = exercise?.resolvedWeightUnit(default: viewModel.units) ?? viewModel.units
        let distanceUnit = exercise?.resolvedDistanceUnit(default: viewModel.distanceUnits) ?? viewModel.distanceUnits

        return ExerciseCardContainer {
            ExerciseCardHeader(name: exercise?.name ?? "Unknown Exercise") {
                Text(exerciseType.displayName)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textTertiary)
            }

            // Exercise notes
            if let notes = exercise?.notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.bottom, .spacingXs)
            }

            SetColumnHeaders(exerciseType: exerciseType, weightUnit: weightUnit, distanceUnit: distanceUnit)

            Rectangle()
                .fill(Color.borderSubtle)
                .frame(height: 1)

            ForEach(Array(sets.enumerated()), id: \.element.id) { index, loggedSet in
                let convertedWeight = convertWeight(loggedSet.weight, storedUnit: loggedSet.resolvedWeightUnit, displayUnit: weightUnit)
                let convertedBWMod = convertWeight(loggedSet.bodyweightModifier, storedUnit: loggedSet.resolvedWeightUnit, displayUnit: weightUnit)
                let convertedDistance = convertDistance(loggedSet.distance, storedUnit: loggedSet.resolvedDistanceUnit, displayUnit: distanceUnit)

                ReadOnlySetRow(
                    exerciseType: exerciseType,
                    setNumber: index + 1,
                    badgeStyle: .completed,
                    weightUnit: weightUnit,
                    distanceUnit: distanceUnit,
                    weight: convertedWeight,
                    reps: loggedSet.reps,
                    bodyweightModifier: convertedBWMod,
                    time: loggedSet.time,
                    distance: convertedDistance,
                    notes: loggedSet.notes
                )
            }

            Spacer()
                .frame(height: .spacingSm)
        }
    }

    // MARK: - Unit Conversion Helpers

    private func convertWeight(_ value: Double?, storedUnit: Units?, displayUnit: Units) -> Double? {
        guard let value else { return nil }
        let from = storedUnit ?? displayUnit
        return value.convert(from: from, to: displayUnit)
    }

    private func convertDistance(_ value: Double?, storedUnit: DistanceUnits?, displayUnit: DistanceUnits) -> Double? {
        guard let value else { return nil }
        let from = storedUnit ?? displayUnit
        return value.convertDistance(from: from, to: displayUnit)
    }
}
