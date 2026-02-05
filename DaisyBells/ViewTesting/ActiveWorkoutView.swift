import SwiftUI

/// Main workout logging screen using List for native swipe-to-delete support
struct ActiveWorkoutView: View {
    let templateName: String?
    let exercises: [MockTemplateExercise]

    @Environment(\.dismiss) private var dismiss

    @State private var startTime = Date()
    @State private var elapsedTime: TimeInterval = 0
    @State private var timerActive = true
    @State private var loggedExercises: [MockLoggedExercise]
    @State private var workoutNotes = ""
    @State private var showingExercisePicker = false
    @State private var completeConfig: ConfirmationDialogConfig?
    @State private var cancelConfig: ConfirmationDialogConfig?
    @State private var deleteExerciseConfig: ConfirmationDialogConfig?
    @State private var isEditing = false

    init(templateName: String? = nil, exercises: [MockTemplateExercise] = []) {
        self.templateName = templateName
        self.exercises = exercises

        let logged = exercises.enumerated().map { index, te in
            MockLoggedExercise(
                exerciseName: te.exerciseName,
                exerciseType: te.exerciseType,
                order: index,
                sets: (0..<(te.targetSets ?? 3)).map { setIndex in
                    MockLoggedSet(order: setIndex)
                }
            )
        }

        _loggedExercises = State(initialValue: logged)
    }

    var body: some View {
        List {
            // MARK: - Header Section
            Section {
                // Title
                Text(templateName ?? "Workout")
                    .font(.title2.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .center)

                // Timer and Start Time
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(startTime, format: .dateTime.month(.abbreviated).day().hour().minute())
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Started")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(formattedTime)
                            .font(.system(.title, design: .monospaced))
                            .fontWeight(.medium)
                        Text("Duration")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        timerActive.toggle()
                    } label: {
                        Image(systemName: timerActive ? "pause.circle.fill" : "play.circle.fill")
                            .font(.title)
                    }
                    .padding(.leading, 8)
                }

                // Notes
                TextField(
                    "Workout notes",
                    text: $workoutNotes,
                    axis: .vertical
                )
                .lineLimit(2...4)
            }

            // MARK: - Exercise Sections
            ForEach(loggedExercises.indices, id: \.self) { index in
                Section {
                    // Set rows with swipe-to-delete
                    ForEach($loggedExercises[index].sets) { $set in
                        let setIndex = loggedExercises[index].sets.firstIndex(where: { $0.id == set.id }) ?? 0
                        LoggedSetEditorView(
                            exerciseType: loggedExercises[index].exerciseType,
                            setNumber: setIndex + 1,
                            weight: $set.weight,
                            reps: $set.reps,
                            bodyweightModifier: $set.bodyweightModifier,
                            time: $set.time,
                            distance: $set.distance,
                            notes: $set.notes
                        )
                    }
                    .onDelete { indexSet in
                        loggedExercises[index].sets.remove(atOffsets: indexSet)
                        reorderSets(at: index)
                    }

                    // Add Set button
                    Button {
                        let newSet = MockLoggedSet(order: loggedExercises[index].sets.count)
                        withAnimation {
                            loggedExercises[index].sets.append(newSet)
                        }
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
                    exerciseHeader(for: index)
                }
            }

            // MARK: - Add Exercise Section
            Section {
                Button {
                    showingExercisePicker = true
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
                        dismiss()
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

                        Button("Cancel Workout", role: .destructive) {
                            cancelConfig = ConfirmationDialogConfig(
                                title: "Discard Workout?",
                                message: "All logged sets will be lost.",
                                confirmTitle: "Discard"
                            ) {
                                dismiss()
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                }
            }
        }
        .sheet(isPresented: $showingExercisePicker) {
            NavigationStack {
                ExercisePickerView { exercise in
                    let logged = MockLoggedExercise(
                        exerciseName: exercise.name,
                        exerciseType: exercise.type,
                        order: loggedExercises.count,
                        sets: [MockLoggedSet(order: 0)]
                    )

                    withAnimation {
                        loggedExercises.append(logged)
                    }
                }
            }
        }
        .confirmationDialog($completeConfig)
        .confirmationDialog($cancelConfig)
        .confirmationDialog($deleteExerciseConfig)
        .onAppear {
            startTimer()
        }
    }

    // MARK: - Helpers
    private var formattedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timerActive {
                elapsedTime += 1
            }
        }
    }

    private func deleteExercise(at index: Int) {
        loggedExercises.remove(at: index)
        reorderExercises()
    }

    private func moveExerciseUp(at index: Int) {
        guard index > 0 else { return }
        loggedExercises.swapAt(index, index - 1)
        reorderExercises()
    }

    private func moveExerciseDown(at index: Int) {
        guard index < loggedExercises.count - 1 else { return }
        loggedExercises.swapAt(index, index + 1)
        reorderExercises()
    }

    private func reorderExercises() {
        for index in loggedExercises.indices {
            loggedExercises[index].order = index
        }
    }

    private func reorderSets(at exerciseIndex: Int) {
        for index in loggedExercises[exerciseIndex].sets.indices {
            loggedExercises[exerciseIndex].sets[index].order = index
        }
    }

    @ViewBuilder
    private func exerciseHeader(for index: Int) -> some View {
        let exercise = loggedExercises[index]
        let isFirst = index == 0
        let isLast = index == loggedExercises.count - 1

        HStack {
            if isEditing {
                Button(role: .destructive) {
                    deleteExerciseConfig = ConfirmationDialogConfig(
                        title: "Delete \(exercise.exerciseName)?",
                        message: "All logged sets for this exercise will be removed.",
                        confirmTitle: "Delete"
                    ) {
                        withAnimation {
                            deleteExercise(at: index)
                        }
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red)
                        .font(.title2)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.exerciseName)
                    .font(.headline)
                    .textCase(nil)
                    .foregroundStyle(Color(.label))
                Text(exercise.exerciseType.displayName)
                    .font(.caption)
                    .textCase(nil)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isEditing {
                HStack(spacing: 12) {
                    Button {
                        withAnimation {
                            moveExerciseUp(at: index)
                        }
                    } label: {
                        Image(systemName: "chevron.up")
                            .font(.title3)
                            .foregroundStyle(isFirst ? .tertiary : .secondary)
                    }
                    .disabled(isFirst)

                    Button {
                        withAnimation {
                            moveExerciseDown(at: index)
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

// MARK: - Previews
#Preview("From Template") {
    NavigationStack {
        ActiveWorkoutView(
            templateName: "Push Day",
            exercises: [
                MockTemplateExercise(
                    exerciseName: "Bench Press",
                    exerciseType: .weightAndReps,
                    order: 0,
                    targetSets: 4,
                    targetReps: 8
                ),
                MockTemplateExercise(
                    exerciseName: "Overhead Press",
                    exerciseType: .weightAndReps,
                    order: 1,
                    targetSets: 3,
                    targetReps: 10
                ),
                MockTemplateExercise(
                    exerciseName: "Dips",
                    exerciseType: .bodyweightAndReps,
                    order: 2,
                    targetSets: 3,
                    targetReps: 12
                )
            ]
        )
    }
}

#Preview("Empty Workout") {
    NavigationStack {
        ActiveWorkoutView()
    }
}
