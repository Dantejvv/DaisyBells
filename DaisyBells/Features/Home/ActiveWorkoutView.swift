import SwiftUI
import SwiftData

@MainActor
struct ActiveWorkoutView: View {
    @State var viewModel: ActiveWorkoutViewModel
    @State private var keyboardCoordinator = KeyboardFocusCoordinator()
    @State private var focusedField: FocusedSetField?

    private func rebuildFocusList() {
        var inputs: [SetFocusInput] = []
        for exercise in viewModel.exercises {
            guard let type = exercise.exercise?.type else { continue }
            let sortedSets = exercise.sets.sorted { $0.order < $1.order }
            for (idx, set) in sortedSets.enumerated() {
                inputs.append(SetFocusInput(
                    exerciseName: exercise.exercise?.name ?? "",
                    exerciseType: type,
                    setNumber: idx + 1,
                    setID: AnyHashable(set.persistentModelID)
                ))
            }
        }
        keyboardCoordinator.update(from: inputs)
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingSpinnerView()
            } else if viewModel.exercises.isEmpty {
                emptyState
            } else {
                workoutContent
            }
        }
        .task { await viewModel.loadWorkout() }
        .confirmationDialog(
            "Cancel Workout",
            isPresented: $viewModel.showCancelConfirmation,
            titleVisibility: .visible
        ) {
            Button("Cancel Workout", role: .destructive) {
                Task { await viewModel.cancelWorkout() }
            }
            Button("Keep Going", role: .cancel) {}
        } message: {
            Text("This will discard all progress. Are you sure?")
        }
        .confirmationDialog(
            "Finish Workout",
            isPresented: $viewModel.showCompleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Finish") {
                Task { await viewModel.completeWorkout() }
            }
            Button("Keep Going", role: .cancel) {}
        } message: {
            Text("Mark this workout as complete?")
        }
        .alert("Save as Template", isPresented: $viewModel.showSaveAsTemplatePrompt) {
            TextField("Template name", text: $viewModel.templateName)
                .submitLabel(.done)
                .textInputAutocapitalization(.words)
                .onSubmit { Task { await viewModel.saveAsTemplate() } }
            Button("Save") {
                Task { await viewModel.saveAsTemplate() }
            }
            Button("Skip", role: .cancel) {
                Task { await viewModel.skipSaveAsTemplate() }
            }
        } message: {
            Text("Save this workout as a reusable template?")
        }
        .errorAlert(errorMessage: $viewModel.errorMessage)
        .background(Color.bgPrimary)
        .tapToDismissKeyboard()
        .navigationBarHidden(true)
        .environment(keyboardCoordinator)
        .onChange(of: viewModel.exercises.map(\.id)) { _, _ in
            rebuildFocusList()
        }
        .onChange(of: viewModel.exercises.flatMap { $0.sets.map(\.id) }) { _, _ in
            rebuildFocusList()
        }
        .task {
            rebuildFocusList()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 0) {
            headerCard
                .padding(.horizontal, .spacingBase)
                .padding(.top, .spacingSm)

            Spacer()

            EmptyStateView(
                icon: "dumbbell",
                title: "No Exercises Yet",
                message: "Add exercises to start logging your workout."
            ) {
                Button("Add Exercise") {
                    viewModel.addExercise()
                }
                .buttonStyle(.borderedProminent)
                .tint(.accent)
            }

            Spacer()
        }
    }

    // MARK: - Workout Content

    private var workoutContent: some View {
        ScrollView {
            VStack(spacing: 14) {
                headerCard

                ForEach(viewModel.exercises, id: \.id) { loggedExercise in
                    ExerciseCard(
                        loggedExercise: loggedExercise,
                        viewModel: viewModel,
                        keyboardCoordinator: keyboardCoordinator,
                        focusedField: $focusedField
                    )
                }

                addExerciseButton
            }
            .padding(.horizontal, .spacingBase)
            .padding(.top, 6)
            .padding(.bottom, .spacing4xl)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Header Card (nav row + status content in one card)

    private var headerCard: some View {
        VStack(spacing: 0) {
            navBar
                .padding(.horizontal, 14)

            statusContent
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 14)
        }
        .padding(.horizontal, 2)
        .cardSurface()
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        InCardNavBar(
            leading: .init(icon: "xmark") {
                viewModel.showCancelConfirmation = true
            },
            trailing: .init(
                label: "Finish Workout",
                isDisabled: viewModel.exercises.isEmpty
            ) {
                viewModel.showCompleteConfirmation = true
            }
        )
    }

    // MARK: - Status Content (inner content of header card)

    private var statusContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Row 1: workout name — full card width, centered, multi-line allowed
            Text(viewModel.fromTemplateName ?? "Workout")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)

            // Row 2: timer (leading) + more button (trailing)
            HStack {
                HStack(spacing: .spacingSm) {
                    PulsingDot()
                    Text(viewModel.elapsedTime.timerString)
                        .font(.system(size: 28, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(Color.accent)
                }

                Spacer()

                Menu {
                    Button {
                        Task { await viewModel.resetTimer() }
                    } label: {
                        Label("Reset Timer", systemImage: "timer")
                    }

                    Button(role: .destructive) {
                        viewModel.showCancelConfirmation = true
                    } label: {
                        Label("Cancel Workout", systemImage: "xmark.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textTertiary)
                        .frame(width: 28, height: 28)
                        .minTouchTarget()
                }
            }
            .padding(.top, 4)

            // Start time
            Text("Started \(viewModel.startedAtFormatted)")
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.textTertiary)
                .padding(.top, .spacingXs)

            // Workout notes
            DebouncedNotesEditor(
                initialValue: viewModel.workoutNotes,
                placeholder: "Notes",
                maxLines: 5,
                onCommit: { await viewModel.updateWorkoutNotes($0) }
            )
            .padding(.top, .spacingXs)

            // Stats row
            Divider()
                .background(Color.borderSubtle)
                .padding(.top, 10)

            HStack(spacing: .spacingBase) {
                Spacer()

                statItem(
                    label: "Exercises",
                    completed: viewModel.completedExercises,
                    total: viewModel.totalExercises,
                    fillColor: Color.accent
                )

                statItem(
                    label: "Sets",
                    completed: viewModel.completedSets,
                    total: viewModel.totalSets,
                    fillColor: Color.success
                )

                Spacer()
            }
            .padding(.top, 10)
        }
    }

    private func statItem(label: String, completed: Int, total: Int, fillColor: Color) -> some View {
        HStack(spacing: .spacingSm) {
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.textTertiary)

            // Progress bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 40, height: 3)

                RoundedRectangle(cornerRadius: 2)
                    .fill(fillColor)
                    .frame(width: total > 0 ? 40 * CGFloat(completed) / CGFloat(total) : 0, height: 3)
            }

            Text("\(completed) / \(total)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.textSecondary)
        }
    }

    // MARK: - Add Exercise Button

    private var addExerciseButton: some View {
        Button {
            viewModel.addExercise()
        } label: {
            HStack(spacing: .spacingSm) {
                Image(systemName: "plus")
                    .font(.footnote.weight(.semibold))
                Text("Add Exercise")
                    .font(.footnote.weight(.semibold))
            }
            .foregroundStyle(Color.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: .radiusLg))
            .overlay(
                RoundedRectangle(cornerRadius: .radiusLg)
                    .strokeBorder(Color.borderDefault, style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
            )
        }
    }
}

// MARK: - Exercise Card

@MainActor
private struct ExerciseCard: View {
    let loggedExercise: SchemaV1.LoggedExercise
    let viewModel: ActiveWorkoutViewModel
    let keyboardCoordinator: KeyboardFocusCoordinator
    @Binding var focusedField: FocusedSetField?
    @State private var exerciseNotesFocused: Bool = false

    var body: some View {
        let exercise = loggedExercise.exercise
        let exerciseType = exercise?.type ?? .weightAndReps
        let sets = loggedExercise.sets.sorted { $0.order < $1.order }
        let previousSets = exercise.flatMap { viewModel.previousPerformance[$0.id] } ?? []
        let firstNonCompletedIndex = sets.firstIndex(where: { !$0.isCompleted })
        let weightUnit = exercise?.resolvedWeightUnit(default: viewModel.defaultWeightUnit) ?? viewModel.defaultWeightUnit
        let distanceUnit = exercise?.resolvedDistanceUnit(default: viewModel.defaultDistanceUnit) ?? viewModel.defaultDistanceUnit

        ExerciseCardContainer {
            ExerciseCardHeader(name: exercise?.name ?? "Unknown Exercise") {
                Menu {
                    if let exercise {
                        ExerciseUnitMenu(
                            exerciseType: exerciseType,
                            currentWeightUnit: weightUnit,
                            currentDistanceUnit: distanceUnit,
                            defaultWeightUnit: viewModel.defaultWeightUnit,
                            defaultDistanceUnit: viewModel.defaultDistanceUnit,
                            onWeightUnitChange: { unit in
                                Task { await viewModel.updateWeightUnit(exercise, unit: unit) }
                            },
                            onDistanceUnitChange: { unit in
                                Task { await viewModel.updateDistanceUnit(exercise, unit: unit) }
                            }
                        )
                    }

                    Button(role: .destructive) {
                        Task { await viewModel.removeExercise(loggedExercise) }
                    } label: {
                        Label("Remove Exercise", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textTertiary)
                        .frame(width: 28, height: 28)
                        .minTouchTarget()
                }
            }

            BridgedTextEditor(
                text: Binding(
                    get: { exercise?.notes ?? "" },
                    set: { newValue in
                        guard let exercise else { return }
                        Task { await viewModel.updateExerciseNotes(exercise, notes: newValue.isEmpty ? nil : newValue) }
                    }
                ),
                placeholder: "Add note...",
                isFocused: $exerciseNotesFocused,
                maxLines: 3,
                font: .systemFont(ofSize: 12),
                textColor: .textSecondary
            )
            .padding(.horizontal, 14)
            .padding(.bottom, 10)

            SetColumnHeaders(exerciseType: exerciseType, showCheckColumn: true, weightUnit: weightUnit, distanceUnit: distanceUnit)

            Rectangle()
                .fill(Color.borderSubtle)
                .frame(height: 1)

            ForEach(Array(sets.enumerated()), id: \.element.id) { index, loggedSet in
                let previousSet = index < previousSets.count ? previousSets[index] : nil
                let sameAsLastSet = index > 0 ? sets[index - 1] : nil
                let isActive = index == firstNonCompletedIndex
                setRow(
                    loggedSet,
                    exerciseType: exerciseType,
                    setNumber: index + 1,
                    previous: previousSet,
                    sameAsLast: sameAsLastSet,
                    isActive: isActive
                )
            }

            HStack {
                Spacer()
                Button {
                    Task { await viewModel.addSet(to: loggedExercise) }
                } label: {
                    Text("+ Add Set")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accent)
                        .padding(.horizontal, .spacingBase)
                        .padding(.vertical, .spacingSm)
                        .contentShape(Rectangle())
                }
                Spacer()
            }
            .padding(.top, .spacingSm)
            .padding(.bottom, 10)
        }
    }

    // MARK: - Set Row

    private func setRow(
        _ loggedSet: SchemaV1.LoggedSet,
        exerciseType: ExerciseType,
        setNumber: Int,
        previous: SchemaV1.LoggedSet?,
        sameAsLast: SchemaV1.LoggedSet?,
        isActive: Bool
    ) -> some View {
        let exercise = loggedExercise.exercise
        let weightUnit = exercise?.resolvedWeightUnit(default: viewModel.defaultWeightUnit) ?? viewModel.defaultWeightUnit
        let distanceUnit = exercise?.resolvedDistanceUnit(default: viewModel.defaultDistanceUnit) ?? viewModel.defaultDistanceUnit

        return HStack(spacing: 0) {
            EditableSetRow(
                exerciseType: exerciseType,
                setNumber: setNumber,
                badgeStyle: loggedSet.isCompleted ? .completed : isActive ? .active : .pending,
                weightUnit: weightUnit,
                distanceUnit: distanceUnit,
                setID: AnyHashable(loggedSet.persistentModelID),
                focusedField: $focusedField,
                weight: loggedSet.weight,
                reps: loggedSet.reps,
                bodyweightModifier: loggedSet.bodyweightModifier,
                time: loggedSet.time,
                distance: loggedSet.distance,
                notes: loggedSet.notes,
                previousWeight: convertWeight(previous?.weight, storedUnit: previous?.resolvedWeightUnit, displayUnit: weightUnit),
                previousReps: previous?.reps,
                previousBodyweightModifier: convertWeight(previous?.bodyweightModifier, storedUnit: previous?.resolvedWeightUnit, displayUnit: weightUnit),
                previousTime: previous?.time,
                previousDistance: convertDistance(previous?.distance, storedUnit: previous?.resolvedDistanceUnit, displayUnit: distanceUnit),
                previousNotes: previous?.notes,
                sameAsLastWeight: sameAsLast?.weight,
                sameAsLastReps: sameAsLast?.reps,
                sameAsLastBodyweightModifier: sameAsLast?.bodyweightModifier,
                sameAsLastTime: sameAsLast?.time,
                sameAsLastDistance: sameAsLast?.distance,
                resolveNextField: { [keyboardCoordinator] field in
                    keyboardCoordinator.next(of: field)
                },
                onWeightChange: { newVal in
                    Task {
                        await viewModel.updateSet(
                            loggedSet, weight: newVal, reps: loggedSet.reps,
                            time: loggedSet.time, distance: loggedSet.distance,
                            bodyweightModifier: loggedSet.bodyweightModifier,
                            notes: loggedSet.notes
                        )
                    }
                },
                onRepsChange: { newVal in
                    Task {
                        await viewModel.updateSet(
                            loggedSet, weight: loggedSet.weight, reps: newVal,
                            time: loggedSet.time, distance: loggedSet.distance,
                            bodyweightModifier: loggedSet.bodyweightModifier,
                            notes: loggedSet.notes
                        )
                    }
                },
                onBodyweightModifierChange: { newVal in
                    Task {
                        await viewModel.updateSet(
                            loggedSet, weight: loggedSet.weight, reps: loggedSet.reps,
                            time: loggedSet.time, distance: loggedSet.distance,
                            bodyweightModifier: newVal,
                            notes: loggedSet.notes
                        )
                    }
                },
                onTimeChange: { newVal in
                    Task {
                        await viewModel.updateSet(
                            loggedSet, weight: loggedSet.weight, reps: loggedSet.reps,
                            time: newVal, distance: loggedSet.distance,
                            bodyweightModifier: loggedSet.bodyweightModifier,
                            notes: loggedSet.notes
                        )
                    }
                },
                onDistanceChange: { newVal in
                    Task {
                        await viewModel.updateSet(
                            loggedSet, weight: loggedSet.weight, reps: loggedSet.reps,
                            time: loggedSet.time, distance: newVal,
                            bodyweightModifier: loggedSet.bodyweightModifier,
                            notes: loggedSet.notes
                        )
                    }
                },
                onNotesChange: { newVal in
                    Task {
                        await viewModel.updateSet(
                            loggedSet, weight: loggedSet.weight, reps: loggedSet.reps,
                            time: loggedSet.time, distance: loggedSet.distance,
                            bodyweightModifier: loggedSet.bodyweightModifier,
                            notes: newVal
                        )
                    }
                }
            )

            checkButton(loggedSet)
                .padding(.trailing, 3)
        }
        .background(
            loggedSet.isCompleted
                ? RoundedRectangle(cornerRadius: .radiusSm)
                    .fill(Color.success.opacity(0.1))
                : nil
        )
        .swipeToDelete(enabled: viewModel.canDeleteSet(loggedSet, from: loggedExercise)) {
            Task { await viewModel.deleteSet(loggedSet, from: loggedExercise) }
        }
        .contextMenu {
            if viewModel.canDeleteSet(loggedSet, from: loggedExercise) {
                Button(role: .destructive) {
                    Task { await viewModel.deleteSet(loggedSet, from: loggedExercise) }
                } label: {
                    Label("Delete Set", systemImage: "trash")
                }
            }
        }
    }

    // MARK: - Check Button

    private func checkButton(_ loggedSet: SchemaV1.LoggedSet) -> some View {
        Button {
            focusedField = nil
            Task { await viewModel.toggleSetCompletion(loggedSet) }
        } label: {
            Group {
                if loggedSet.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(Color.success)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .stroke(Color.borderDefault, lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                }
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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

// MARK: - Pulsing Dot

private struct PulsingDot: View {
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .fill(Color.success)
            .frame(width: 6, height: 6)
            .opacity(isAnimating ? 0.35 : 1.0)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear { isAnimating = true }
    }
}
