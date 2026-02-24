import SwiftUI
import SwiftData

@MainActor
struct ActiveWorkoutView: View {
    @State var viewModel: ActiveWorkoutViewModel

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
                viewModel.skipSaveAsTemplate()
            }
        } message: {
            Text("Save this workout as a reusable template?")
        }
        .errorAlert(errorMessage: $viewModel.errorMessage)
        .background(Color.bgPrimary)
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
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
                }
            }

            // Start time
            Text("Started \(viewModel.startedAtFormatted)")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.textTertiary)
                .padding(.top, .spacingSm)

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

        return ExerciseCardContainer {
            // Card header
            ExerciseCardHeader(name: exercise?.name ?? "Unknown Exercise") {
                Menu {
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
                }
            }

            // Column headers
            SetColumnHeaders(exerciseType: exerciseType, showCheckColumn: true)

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
            Button {
                Task { await viewModel.addSet(to: loggedExercise) }
            } label: {
                Text("+ Add Set")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.top, .spacingSm)
                    .padding(.bottom, 10)
            }
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
        HStack(spacing: 6) {
            // Set number badge
            SetNumberBadge(
                number: setNumber,
                style: loggedSet.isCompleted ? .completed : isActive ? .active : .pending
            )

            // Input pills based on exercise type — show previous values as placeholders
            switch exerciseType {
            case .weightAndReps:
                let leftPH = previous?.weight.map { String(format: "%g", $0) } ?? "lbs"
                let rightPH = previous?.reps.map { "\($0)" } ?? "reps"
                dualInputPill(
                    leftValue: loggedSet.weight,
                    rightValue: loggedSet.reps.map { Double($0) },
                    leftPlaceholder: leftPH,
                    rightPlaceholder: rightPH,
                    isCompleted: loggedSet.isCompleted,
                    onLeftCommit: { newVal in
                        Task {
                            await viewModel.updateSet(
                                loggedSet, weight: newVal, reps: loggedSet.reps,
                                time: loggedSet.time, distance: loggedSet.distance,
                                bodyweightModifier: loggedSet.bodyweightModifier
                            )
                        }
                    },
                    onRightCommit: { newVal in
                        Task {
                            await viewModel.updateSet(
                                loggedSet, weight: loggedSet.weight, reps: newVal.map { Int($0) } ?? nil,
                                time: loggedSet.time, distance: loggedSet.distance,
                                bodyweightModifier: loggedSet.bodyweightModifier
                            )
                        }
                    }
                )
            case .bodyweightAndReps:
                let leftPH = previous?.bodyweightModifier.map { String(format: "%+g", $0) } ?? "+/-"
                let rightPH = previous?.reps.map { "\($0)" } ?? "reps"
                dualInputPill(
                    leftValue: loggedSet.bodyweightModifier,
                    rightValue: loggedSet.reps.map { Double($0) },
                    leftPlaceholder: leftPH,
                    rightPlaceholder: rightPH,
                    isCompleted: loggedSet.isCompleted,
                    onLeftCommit: { newVal in
                        Task {
                            await viewModel.updateSet(
                                loggedSet, weight: loggedSet.weight, reps: loggedSet.reps,
                                time: loggedSet.time, distance: loggedSet.distance,
                                bodyweightModifier: newVal
                            )
                        }
                    },
                    onRightCommit: { newVal in
                        Task {
                            await viewModel.updateSet(
                                loggedSet, weight: loggedSet.weight, reps: newVal.map { Int($0) } ?? nil,
                                time: loggedSet.time, distance: loggedSet.distance,
                                bodyweightModifier: loggedSet.bodyweightModifier
                            )
                        }
                    }
                )
            case .distanceAndTime:
                let leftPH = previous?.distance.map { String(format: "%.1f", $0) } ?? "dist"
                let rightPH = previous?.time.map { $0.setDurationString } ?? "m:ss"
                dualInputPill(
                    leftValue: loggedSet.distance,
                    rightValue: loggedSet.time,
                    leftPlaceholder: leftPH,
                    rightPlaceholder: rightPH,
                    isCompleted: loggedSet.isCompleted,
                    onLeftCommit: { newVal in
                        Task {
                            await viewModel.updateSet(
                                loggedSet, weight: loggedSet.weight, reps: loggedSet.reps,
                                time: loggedSet.time, distance: newVal,
                                bodyweightModifier: loggedSet.bodyweightModifier
                            )
                        }
                    },
                    onRightCommit: { newVal in
                        Task {
                            await viewModel.updateSet(
                                loggedSet, weight: loggedSet.weight, reps: loggedSet.reps,
                                time: newVal, distance: loggedSet.distance,
                                bodyweightModifier: loggedSet.bodyweightModifier
                            )
                        }
                    }
                )
            case .weightAndTime:
                let leftPH = previous?.weight.map { String(format: "%g", $0) } ?? "lbs"
                let rightPH = previous?.time.map { $0.setDurationString } ?? "m:ss"
                dualInputPill(
                    leftValue: loggedSet.weight,
                    rightValue: loggedSet.time,
                    leftPlaceholder: leftPH,
                    rightPlaceholder: rightPH,
                    isCompleted: loggedSet.isCompleted,
                    onLeftCommit: { newVal in
                        Task {
                            await viewModel.updateSet(
                                loggedSet, weight: newVal, reps: loggedSet.reps,
                                time: loggedSet.time, distance: loggedSet.distance,
                                bodyweightModifier: loggedSet.bodyweightModifier
                            )
                        }
                    },
                    onRightCommit: { newVal in
                        Task {
                            await viewModel.updateSet(
                                loggedSet, weight: loggedSet.weight, reps: loggedSet.reps,
                                time: newVal, distance: loggedSet.distance,
                                bodyweightModifier: loggedSet.bodyweightModifier
                            )
                        }
                    }
                )
            case .reps:
                let ph = previous?.reps.map { "\($0)" } ?? "reps"
                singleInputPill(
                    value: loggedSet.reps.map { Double($0) },
                    placeholder: ph,
                    isCompleted: loggedSet.isCompleted,
                    onCommit: { newVal in
                        Task {
                            await viewModel.updateSet(
                                loggedSet, weight: loggedSet.weight, reps: newVal.map { Int($0) } ?? nil,
                                time: loggedSet.time, distance: loggedSet.distance,
                                bodyweightModifier: loggedSet.bodyweightModifier
                            )
                        }
                    }
                )
            case .time:
                let ph = previous?.time.map { $0.setDurationString } ?? "m:ss"
                singleInputPill(
                    value: loggedSet.time,
                    placeholder: ph,
                    isCompleted: loggedSet.isCompleted,
                    onCommit: { newVal in
                        Task {
                            await viewModel.updateSet(
                                loggedSet, weight: loggedSet.weight, reps: loggedSet.reps,
                                time: newVal, distance: loggedSet.distance,
                                bodyweightModifier: loggedSet.bodyweightModifier
                            )
                        }
                    }
                )
            }

            // Notes field
            notesField(loggedSet, previous: previous)

            // Check button
            checkButton(loggedSet)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .contextMenu {
            Button(role: .destructive) {
                Task { await viewModel.deleteSet(loggedSet, from: loggedExercise) }
            } label: {
                Label("Delete Set", systemImage: "trash")
            }
        }
    }

    // MARK: - Fused Input Pills

    private func dualInputPill(
        leftValue: Double?,
        rightValue: Double?,
        leftPlaceholder: String,
        rightPlaceholder: String,
        isCompleted: Bool,
        onLeftCommit: @escaping (Double?) -> Void,
        onRightCommit: @escaping (Double?) -> Void
    ) -> some View {
        HStack(spacing: 0) {
            pillTextField(value: leftValue, placeholder: leftPlaceholder, onCommit: onLeftCommit)
            Rectangle()
                .fill(Color.borderDefault)
                .frame(width: 1, height: 16)
            pillTextField(value: rightValue, placeholder: rightPlaceholder, onCommit: onRightCommit)
        }
        .frame(width: 94)
        .background(Color.bgInput)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.borderSubtle, lineWidth: 1)
        )
    }

    private func singleInputPill(
        value: Double?,
        placeholder: String,
        isCompleted: Bool,
        onCommit: @escaping (Double?) -> Void
    ) -> some View {
        pillTextField(value: value, placeholder: placeholder, onCommit: onCommit)
            .frame(width: 46)
            .background(Color.bgInput)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.borderSubtle, lineWidth: 1)
            )
    }

    private func pillTextField(value: Double?, placeholder: String, onCommit: @escaping (Double?) -> Void) -> some View {
        let text = value.map { String(format: "%g", $0) } ?? ""
        return TextField(placeholder, text: Binding(
            get: { text },
            set: { newText in
                let cleaned = newText.filter { $0.isNumber || $0 == "." || $0 == "-" }
                onCommit(Double(cleaned))
            }
        ))
        .keyboardType(.decimalPad)
        .font(.system(size: 13))
        .foregroundStyle(Color.textPrimary)
        .multilineTextAlignment(.center)
        .padding(.vertical, 5)
        .padding(.horizontal, 4)
    }

    // MARK: - Notes Field

    private func notesField(_ loggedSet: SchemaV1.LoggedSet, previous: SchemaV1.LoggedSet?) -> some View {
        let currentNotes = loggedSet.notes ?? ""
        let placeholderText = previous?.notes ?? "Notes..."

        return TextField(
            placeholderText,
            text: Binding(
                get: { currentNotes },
                set: { newValue in
                    Task {
                        await viewModel.updateSet(
                            loggedSet,
                            weight: loggedSet.weight,
                            reps: loggedSet.reps,
                            time: loggedSet.time,
                            distance: loggedSet.distance,
                            bodyweightModifier: loggedSet.bodyweightModifier,
                            notes: newValue.isEmpty ? nil : newValue
                        )
                    }
                }
            )
        )
        .font(.system(size: 11))
        .italic(currentNotes.isEmpty)
        .foregroundStyle(currentNotes.isEmpty ? Color.textTertiary : Color.textSecondary)
        .padding(.horizontal, .spacingSm)
        .padding(.vertical, .spacingSm)
        .background(currentNotes.isEmpty ? Color.clear : Color.white.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: .radiusSm))
        .overlay(
            RoundedRectangle(cornerRadius: .radiusSm)
                .stroke(Color.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Check Button

    private func checkButton(_ loggedSet: SchemaV1.LoggedSet) -> some View {
        Button {
            Task { await viewModel.toggleSetCompletion(loggedSet) }
        } label: {
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
