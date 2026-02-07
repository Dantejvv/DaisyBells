import SwiftUI

/// Main workout logging screen using List for native swipe-to-delete support
struct ActiveWorkoutView: View {
    @State private var viewModel: ActiveWorkoutViewModel
    @State private var completeConfig: ConfirmationDialogConfig?
    @State private var cancelConfig: ConfirmationDialogConfig?
    @State private var deleteExerciseConfig: ConfirmationDialogConfig?
    @State private var isEditing = false

    init(viewModel: ActiveWorkoutViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingSpinnerView(message: "Loading workout...")
            } else {
                workoutContent
            }
        }
        .errorAlert(Binding(
            get: { viewModel.errorMessage },
            set: { viewModel.errorMessage = $0 }
        ))
        .task { await viewModel.loadWorkout() }
    }

    @ViewBuilder
    private var workoutContent: some View {
        List {
            // MARK: - Header Section
            Section {
                // Title
                Text(viewModel.fromTemplateName ?? "Workout")
                    .font(.title2.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .center)

                // Timer and Start Time
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        if let workout = viewModel.workout {
                            Text(workout.startedAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        Text("Started")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(viewModel.elapsedTime.timerString)
                            .font(.system(.title, design: .monospaced))
                            .fontWeight(.medium)
                        Text("Duration")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Notes
                TextField(
                    "Workout notes",
                    text: $viewModel.workoutNotes,
                    axis: .vertical
                )
                .lineLimit(2...4)
                .onChange(of: viewModel.workoutNotes) { _, newValue in
                    Task { await viewModel.updateWorkoutNotes(newValue) }
                }
            }

            // MARK: - Exercise Sections
            ForEach(Array(viewModel.exercises.enumerated()), id: \.element.id) { exerciseIndex, loggedExercise in
                Section {
                    // Set rows with swipe-to-delete
                    let sortedSets = loggedExercise.sets.sorted { $0.order < $1.order }
                    ForEach(Array(sortedSets.enumerated()), id: \.element.id) { setIndex, loggedSet in
                        SetEditorRow(
                            exerciseType: loggedExercise.exercise?.type ?? .weightAndReps,
                            setNumber: setIndex + 1,
                            loggedSet: loggedSet,
                            onUpdate: { weight, reps, time, distance, bodyweightModifier, notes in
                                Task {
                                    await viewModel.updateSet(
                                        loggedSet,
                                        weight: weight,
                                        reps: reps,
                                        time: time,
                                        distance: distance,
                                        bodyweightModifier: bodyweightModifier,
                                        notes: notes
                                    )
                                }
                            }
                        )
                    }
                    .onDelete { indexSet in
                        let sorted = loggedExercise.sets.sorted { $0.order < $1.order }
                        for index in indexSet {
                            let set = sorted[index]
                            Task { await viewModel.deleteSet(set, from: loggedExercise) }
                        }
                    }

                    // Add Set button
                    Button {
                        Task { await viewModel.addSet(to: loggedExercise) }
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                            Text("Add Set")
                                .font(.body)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    exerciseHeader(for: exerciseIndex)
                }
            }

            // MARK: - Add Exercise Section
            Section {
                Button {
                    viewModel.addExercise()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("Add Exercise")
                            .font(.body)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(.compact)
        .contentMargins(.top, 0, for: .scrollContent)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    completeConfig = ConfirmationDialogConfig(
                        title: "Complete Workout?",
                        message: "This will save your workout to history.",
                        confirmTitle: "Complete",
                        confirmRole: nil
                    ) {
                        Task { await viewModel.completeWorkout() }
                    }
                } label: {
                    Text("Complete")
                        .fontWeight(.semibold)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                if isEditing {
                    Button("Done") {
                        withAnimation {
                            isEditing = false
                        }
                    }
                    .fontWeight(.semibold)
                } else {
                    Menu {
                        Button("Edit Workout") {
                            withAnimation {
                                isEditing = true
                            }
                        }

                        Button {
                            viewModel.templateName = viewModel.fromTemplateName ?? ""
                            viewModel.showSaveAsTemplatePrompt = true
                        } label: {
                            Label("Save as Template", systemImage: "square.and.arrow.down")
                        }

                        Button("Cancel Workout", role: .destructive) {
                            cancelConfig = ConfirmationDialogConfig(
                                title: "Discard Workout?",
                                message: "All logged sets will be lost.",
                                confirmTitle: "Discard"
                            ) {
                                Task { await viewModel.cancelWorkout() }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                }
            }
        }
        .confirmationDialog($completeConfig)
        .confirmationDialog($cancelConfig)
        .confirmationDialog($deleteExerciseConfig)
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
    }

    // MARK: - Exercise Header

    @ViewBuilder
    private func exerciseHeader(for index: Int) -> some View {
        let exercise = viewModel.exercises[index]
        let isFirst = index == 0
        let isLast = index == viewModel.exercises.count - 1

        HStack {
            if isEditing {
                Button(role: .destructive) {
                    deleteExerciseConfig = ConfirmationDialogConfig(
                        title: "Delete \(exercise.exercise?.name ?? "Exercise")?",
                        message: "All logged sets for this exercise will be removed.",
                        confirmTitle: "Delete"
                    ) {
                        Task { await viewModel.removeExercise(exercise) }
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red)
                        .font(.title2)
                }
            }

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

            if isEditing {
                HStack(spacing: 12) {
                    Button {
                        guard index > 0 else { return }
                        withAnimation {
                            viewModel.reorderExercises(
                                from: IndexSet(integer: index),
                                to: index - 1
                            )
                        }
                    } label: {
                        Image(systemName: "chevron.up")
                            .font(.title3)
                            .foregroundStyle(isFirst ? .tertiary : .secondary)
                    }
                    .disabled(isFirst)

                    Button {
                        guard index < viewModel.exercises.count - 1 else { return }
                        withAnimation {
                            viewModel.reorderExercises(
                                from: IndexSet(integer: index),
                                to: index + 2
                            )
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.title3)
                            .foregroundStyle(isLast ? .tertiary : .secondary)
                    }
                    .disabled(isLast)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Set Editor Row (wraps LoggedSetEditorView with bindings to LoggedSet)

private struct SetEditorRow: View {
    let exerciseType: ExerciseType
    let setNumber: Int
    let loggedSet: SchemaV1.LoggedSet
    let onUpdate: (Double?, Int?, TimeInterval?, Double?, Double?, String?) -> Void

    @State private var weight: Double?
    @State private var reps: Int?
    @State private var time: TimeInterval?
    @State private var distance: Double?
    @State private var bodyweightModifier: Double?
    @State private var notes: String

    init(
        exerciseType: ExerciseType,
        setNumber: Int,
        loggedSet: SchemaV1.LoggedSet,
        onUpdate: @escaping (Double?, Int?, TimeInterval?, Double?, Double?, String?) -> Void
    ) {
        self.exerciseType = exerciseType
        self.setNumber = setNumber
        self.loggedSet = loggedSet
        self.onUpdate = onUpdate
        _weight = State(initialValue: loggedSet.weight)
        _reps = State(initialValue: loggedSet.reps)
        _time = State(initialValue: loggedSet.time)
        _distance = State(initialValue: loggedSet.distance)
        _bodyweightModifier = State(initialValue: loggedSet.bodyweightModifier)
        _notes = State(initialValue: loggedSet.notes ?? "")
    }

    var body: some View {
        LoggedSetEditorView(
            exerciseType: exerciseType,
            setNumber: setNumber,
            weight: $weight,
            reps: $reps,
            bodyweightModifier: $bodyweightModifier,
            time: $time,
            distance: $distance,
            notes: $notes
        )
        .onChange(of: weight) { _, _ in sendUpdate() }
        .onChange(of: reps) { _, _ in sendUpdate() }
        .onChange(of: time) { _, _ in sendUpdate() }
        .onChange(of: distance) { _, _ in sendUpdate() }
        .onChange(of: bodyweightModifier) { _, _ in sendUpdate() }
        .onChange(of: notes) { _, _ in sendUpdate() }
    }

    private func sendUpdate() {
        onUpdate(weight, reps, time, distance, bodyweightModifier, notes.isEmpty ? nil : notes)
    }
}
