import SwiftUI
import SwiftData

@MainActor
struct ActiveWorkoutView: View {
    @State var viewModel: ActiveWorkoutViewModel
    @State private var notesDraft: String = ""
    @State private var notesPersistTask: Task<Void, Never>?
    @FocusState private var focusedField: FocusedSetField?
    @FocusState private var workoutNotesFocused: Bool
    @FocusState private var exerciseNotesFocused: Bool

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
        .navigationBarHidden(true)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 0) {
            navBar
                .padding(.horizontal, .spacingBase)

            statusCard
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
                navBar

                statusCard

                ForEach(viewModel.exercises, id: \.id) { loggedExercise in
                    exerciseCard(loggedExercise)
                }

                addExerciseButton
            }
            .padding(.horizontal, .spacingBase)
            .padding(.bottom, .spacing4xl)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack {
            Button {
                viewModel.showCancelConfirmation = true
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
                    .minTouchTarget()
            }

            Spacer()

            Button {
                viewModel.showCompleteConfirmation = true
            } label: {
                Text("Finish Workout")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.bgPrimary)
                    .padding(.horizontal, .spacingBase)
                    .padding(.vertical, 7)
                    .background(Color.accent)
                    .clipShape(Capsule())
                    .minTouchTarget()
            }
            .disabled(viewModel.exercises.isEmpty)
        }
        .padding(.vertical, .spacingSm)
    }

    // MARK: - Status Card

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top row: timer + name + more button
            HStack {
                // Left: pulsing dot + timer
                HStack(spacing: .spacingSm) {
                    PulsingDot()
                    Text(viewModel.elapsedTime.timerString)
                        .font(.system(size: 28, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(Color.accent)
                }

                Spacer()

                // Center: workout name
                Text(viewModel.fromTemplateName ?? "Workout")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                // Right: more button
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

            // Start time
            Text("Started \(viewModel.startedAtFormatted)")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.textTertiary)
                .padding(.top, .spacingSm)

            // Workout notes
            TextField("Notes", text: $notesDraft, axis: .vertical)
                .font(.system(size: 13))
                .foregroundStyle(Color.textSecondary)
                .lineLimit(1...5)
                .frame(minHeight: 44)
                .focused($workoutNotesFocused)
                .doneKeyboardToolbar(isFocused: workoutNotesFocused) { workoutNotesFocused = false }
                .padding(.top, .spacingSm)
                .onChange(of: notesDraft) { _, newValue in
                    notesPersistTask?.cancel()
                    notesPersistTask = Task {
                        try? await Task.sleep(for: .milliseconds(500))
                        if Task.isCancelled { return }
                        await viewModel.updateWorkoutNotes(newValue)
                    }
                }
                .onChange(of: viewModel.workoutNotes) { _, newValue in
                    if notesPersistTask == nil && notesDraft != newValue {
                        notesDraft = newValue
                    }
                }
                .task {
                    notesDraft = viewModel.workoutNotes
                }

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
        .padding(14)
        .padding(.horizontal, 2)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: .radiusLg))
        .overlay(
            RoundedRectangle(cornerRadius: .radiusLg)
                .stroke(Color.borderSubtle, lineWidth: 1)
        )
    }

    private func statItem(label: String, completed: Int, total: Int, fillColor: Color) -> some View {
        HStack(spacing: .spacingSm) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
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
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
        }
    }

    // MARK: - Exercise Card

    private func exerciseCard(_ loggedExercise: SchemaV1.LoggedExercise) -> some View {
        let exercise = loggedExercise.exercise
        let exerciseType = exercise?.type ?? .weightAndReps
        let sets = loggedExercise.sets.sorted { $0.order < $1.order }
        let previousSets = exercise.flatMap { viewModel.previousPerformance[$0.id] } ?? []
        let firstNonCompletedIndex = sets.firstIndex(where: { !$0.isCompleted })
        let weightUnit = exercise?.resolvedWeightUnit(default: viewModel.defaultWeightUnit) ?? viewModel.defaultWeightUnit
        let distanceUnit = exercise?.resolvedDistanceUnit(default: viewModel.defaultDistanceUnit) ?? viewModel.defaultDistanceUnit

        return ExerciseCardContainer {
            // Card header
            ExerciseCardHeader(name: exercise?.name ?? "Unknown Exercise") {
                Menu {
                    if let exercise {
                        unitMenuSection(exercise: exercise, exerciseType: exerciseType)
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

            // Exercise notes
            TextField("Add note...", text: Binding(
                get: { exercise?.notes ?? "" },
                set: { newValue in
                    guard let exercise else { return }
                    Task { await viewModel.updateExerciseNotes(exercise, notes: newValue.isEmpty ? nil : newValue) }
                }
            ), axis: .vertical)
            .font(.system(size: 12))
            .foregroundStyle(Color.textSecondary)
            .lineLimit(1...3)
            .frame(minHeight: 44)
            .focused($exerciseNotesFocused)
            .doneKeyboardToolbar(isFocused: exerciseNotesFocused) { exerciseNotesFocused = false }
            .padding(.horizontal, 14)
            .padding(.bottom, .spacingXs)

            // Column headers
            SetColumnHeaders(exerciseType: exerciseType, showCheckColumn: true, weightUnit: weightUnit, distanceUnit: distanceUnit)

            // Divider below headers
            Rectangle()
                .fill(Color.borderSubtle)
                .frame(height: 1)

            // Set rows
            ForEach(Array(sets.enumerated()), id: \.element.id) { index, loggedSet in
                let previousSet = index < previousSets.count ? previousSets[index] : nil
                let isActive = index == firstNonCompletedIndex
                setRow(
                    loggedSet,
                    exerciseType: exerciseType,
                    setNumber: index + 1,
                    previous: previousSet,
                    isActive: isActive,
                    loggedExercise: loggedExercise
                )
            }

            // Add set button
            HStack {
                Spacer()
                Button {
                    Task { await viewModel.addSet(to: loggedExercise) }
                } label: {
                    Text("+ Add Set")
                        .font(.system(size: 12, weight: .semibold))
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
        isActive: Bool,
        loggedExercise: SchemaV1.LoggedExercise
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

    // MARK: - Add Exercise Button

    private var addExerciseButton: some View {
        Button {
            viewModel.addExercise()
        } label: {
            HStack(spacing: .spacingSm) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .semibold))
                Text("Add Exercise")
                    .font(.system(size: 13, weight: .semibold))
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

    // MARK: - Unit Menu

    @ViewBuilder
    private func unitMenuSection(exercise: SchemaV1.Exercise, exerciseType: ExerciseType) -> some View {
        switch exerciseType {
        case .weightAndReps, .bodyweightAndReps, .weightAndTime:
            Picker("Weight Unit", selection: Binding(
                get: { exercise.preferredWeightUnit ?? viewModel.defaultWeightUnit },
                set: { newUnit in
                    Task {
                        await viewModel.updateWeightUnit(
                            exercise,
                            unit: newUnit == viewModel.defaultWeightUnit ? nil : newUnit
                        )
                    }
                }
            )) {
                ForEach(Units.allCases, id: \.self) { unit in
                    Text(unit.displayName).tag(unit)
                }
            }
            .pickerStyle(.inline)
        case .distanceAndTime:
            Picker("Distance Unit", selection: Binding(
                get: { exercise.preferredDistanceUnit ?? viewModel.defaultDistanceUnit },
                set: { newUnit in
                    Task {
                        await viewModel.updateDistanceUnit(
                            exercise,
                            unit: newUnit == viewModel.defaultDistanceUnit ? nil : newUnit
                        )
                    }
                }
            )) {
                ForEach(DistanceUnits.allCases, id: \.self) { unit in
                    Text(unit.displayName).tag(unit)
                }
            }
            .pickerStyle(.inline)
        case .reps, .time:
            EmptyView()
        }
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
