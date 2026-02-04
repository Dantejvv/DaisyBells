import SwiftUI

/// Main workout logging screen with timer, exercises, and sets
struct ActiveWorkoutView: View {
    let templateName: String?
    let exercises: [MockTemplateExercise]

    @Environment(\.dismiss) private var dismiss

    @State private var elapsedTime: TimeInterval = 0
    @State private var timerActive = true
    @State private var loggedExercises: [MockLoggedExercise]
    @State private var workoutNotes = ""
    @State private var showingExercisePicker = false
    @State private var completeConfig: ConfirmationDialogConfig?
    @State private var cancelConfig: ConfirmationDialogConfig?

    init(templateName: String? = nil, exercises: [MockTemplateExercise] = []) {
        self.templateName = templateName
        self.exercises = exercises

        // Convert template exercises to logged exercises
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
            // Timer section
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formattedTime)
                            .font(.system(.title, design: .monospaced))
                            .fontWeight(.medium)
                        Text("Duration")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        timerActive.toggle()
                    } label: {
                        Image(systemName: timerActive ? "pause.circle.fill" : "play.circle.fill")
                            .font(.title)
                    }
                }
            }

            // Exercises
            ForEach($loggedExercises) { $exercise in
                Section {
                    // Exercise header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(exercise.exerciseName)
                                .font(.headline)
                            Spacer()
                            Text(exercise.exerciseType.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        // Column headers
                        columnHeaders(for: exercise.exerciseType)
                    }

                    // Sets
                    ForEach($exercise.sets) { $set in
                        LoggedSetRow(
                            exerciseType: exercise.exerciseType,
                            set: $set
                        )
                    }
                    .onDelete { indexSet in
                        exercise.sets.remove(atOffsets: indexSet)
                        reorderSets(for: &exercise)
                    }

                    // Add set button
                    Button {
                        let newSet = MockLoggedSet(order: exercise.sets.count)
                        withAnimation {
                            exercise.sets.append(newSet)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Set")
                        }
                        .font(.subheadline)
                    }

                    // Exercise notes
                    TextField("Notes for this exercise...", text: $exercise.notes, axis: .vertical)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2...4)
                }
            }
            .onDelete { indexSet in
                loggedExercises.remove(atOffsets: indexSet)
                reorderExercises()
            }
            .onMove { from, to in
                loggedExercises.move(fromOffsets: from, toOffset: to)
                reorderExercises()
            }

            // Add exercise button
            Section {
                Button {
                    showingExercisePicker = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Exercise")
                    }
                }
            }

            // Workout notes
            Section("Workout Notes") {
                TextField("How did the workout feel?", text: $workoutNotes, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
        .navigationTitle(templateName ?? "Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    cancelConfig = ConfirmationDialogConfig(
                        title: "Discard Workout?",
                        message: "All logged sets will be lost.",
                        confirmTitle: "Discard"
                    ) {
                        dismiss()
                    }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Complete") {
                    completeConfig = ConfirmationDialogConfig(
                        title: "Complete Workout?",
                        message: "This will save your workout to history.",
                        confirmTitle: "Complete",
                        confirmRole: nil
                    ) {
                        dismiss()
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
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
        .onAppear {
            startTimer()
        }
    }

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

    @ViewBuilder
    private func columnHeaders(for type: MockExerciseType) -> some View {
        HStack(spacing: 12) {
            Text("SET")
                .frame(width: 24)

            switch type {
            case .weightAndReps:
                Text("WEIGHT")
                    .frame(width: 70, alignment: .leading)
                Text("REPS")
                    .frame(width: 50, alignment: .leading)

            case .bodyweightAndReps:
                Text("MOD %")
                    .frame(width: 60, alignment: .leading)
                Text("REPS")
                    .frame(width: 50, alignment: .leading)

            case .reps:
                Text("REPS")
                    .frame(width: 50, alignment: .leading)

            case .time:
                Text("TIME")
                    .frame(width: 50, alignment: .leading)

            case .distanceAndTime:
                Text("DIST")
                    .frame(width: 60, alignment: .leading)
                Text("TIME")
                    .frame(width: 50, alignment: .leading)

            case .weightAndTime:
                Text("WEIGHT")
                    .frame(width: 70, alignment: .leading)
                Text("TIME")
                    .frame(width: 50, alignment: .leading)
            }

            Spacer()
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }

    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timerActive {
                elapsedTime += 1
            }
        }
    }

    private func reorderExercises() {
        for (index, _) in loggedExercises.enumerated() {
            loggedExercises[index].order = index
        }
    }

    private func reorderSets(for exercise: inout MockLoggedExercise) {
        for (index, _) in exercise.sets.enumerated() {
            exercise.sets[index].order = index
        }
    }
}

private struct LoggedSetRow: View {
    let exerciseType: MockExerciseType
    @Binding var set: MockLoggedSet

    var body: some View {
        LoggedSetEditorView(
            exerciseType: exerciseType,
            setNumber: set.order + 1,
            weight: $set.weight,
            reps: $set.reps,
            bodyweightModifier: $set.bodyweightModifier,
            time: $set.time,
            distance: $set.distance
        )
    }
}

#Preview("From Template") {
    NavigationStack {
        ActiveWorkoutView(
            templateName: "Push Day",
            exercises: [
                MockTemplateExercise(exerciseName: "Bench Press", exerciseType: .weightAndReps, order: 0, targetSets: 4, targetReps: 8),
                MockTemplateExercise(exerciseName: "Overhead Press", exerciseType: .weightAndReps, order: 1, targetSets: 3, targetReps: 10),
                MockTemplateExercise(exerciseName: "Dips", exerciseType: .bodyweightAndReps, order: 2, targetSets: 3, targetReps: 12),
            ]
        )
    }
}

#Preview("Empty Workout") {
    NavigationStack {
        ActiveWorkoutView()
    }
}
