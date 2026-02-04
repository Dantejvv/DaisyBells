import SwiftUI

/// Create or edit a workout template
struct TemplateFormView: View {
    let template: MockTemplate?

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var notes: String
    @State private var exercises: [MockTemplateExercise]
    @State private var showingExercisePicker = false
    @State private var errorMessage: String?

    private var isEditing: Bool { template != nil }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    init(template: MockTemplate?) {
        self.template = template
        _name = State(initialValue: template?.name ?? "")
        _notes = State(initialValue: template?.notes ?? "")
        _exercises = State(initialValue: template?.exercises ?? [])
    }

    var body: some View {
        Form {
            Section("Template Info") {
                TextField("Name", text: $name)
                TextField("Notes (optional)", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
            }

            Section {
                if exercises.isEmpty {
                    Text("No exercises added")
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
                    ForEach(exercises) { exercise in
                        TemplateExerciseEditRow(
                            exercise: exercise,
                            onUpdateSets: { newSets in
                                if let index = exercises.firstIndex(where: { $0.id == exercise.id }) {
                                    exercises[index].targetSets = newSets
                                }
                            },
                            onUpdateReps: { newReps in
                                if let index = exercises.firstIndex(where: { $0.id == exercise.id }) {
                                    exercises[index].targetReps = newReps
                                }
                            }
                        )
                    }
                    .onDelete { indexSet in
                        exercises.remove(atOffsets: indexSet)
                        reorderExercises()
                    }
                    .onMove { from, to in
                        exercises.move(fromOffsets: from, toOffset: to)
                        reorderExercises()
                    }
                }

                Button {
                    showingExercisePicker = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Exercise")
                    }
                }
            } header: {
                HStack {
                    Text("Exercises")
                    Spacer()
                    if !exercises.isEmpty {
                        EditButton()
                            .font(.caption)
                    }
                }
            }
        }
        .navigationTitle(isEditing ? "Edit Template" : "New Template")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
                .disabled(!canSave)
            }
        }
        .sheet(isPresented: $showingExercisePicker) {
            NavigationStack {
                ExercisePickerView { exercise in
                    let templateExercise = MockTemplateExercise(
                        exerciseName: exercise.name,
                        exerciseType: exercise.type,
                        order: exercises.count,
                        targetSets: 3,
                        targetReps: exercise.type == .weightAndReps || exercise.type == .bodyweightAndReps ? 10 : nil
                    )
                    exercises.append(templateExercise)
                }
            }
        }
        .errorAlert($errorMessage)
    }

    private func reorderExercises() {
        for (index, _) in exercises.enumerated() {
            exercises[index].order = index
        }
    }

    private func save() {
        guard canSave else {
            errorMessage = "Please enter a template name."
            return
        }
        dismiss()
    }
}

private struct TemplateExerciseEditRow: View {
    let exercise: MockTemplateExercise
    let onUpdateSets: (Int?) -> Void
    let onUpdateReps: (Int?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(exercise.exerciseName)
                    .font(.body)
                Spacer()
                Text(exercise.exerciseType.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                HStack(spacing: 8) {
                    Text("Sets:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Stepper(
                        "\(exercise.targetSets ?? 0)",
                        value: Binding(
                            get: { exercise.targetSets ?? 0 },
                            set: { onUpdateSets($0 > 0 ? $0 : nil) }
                        ),
                        in: 0...20
                    )
                    .labelsHidden()
                    Text("\(exercise.targetSets ?? 0)")
                        .font(.subheadline)
                        .frame(minWidth: 20)
                }

                if exercise.exerciseType == .weightAndReps || exercise.exerciseType == .bodyweightAndReps || exercise.exerciseType == .reps {
                    HStack(spacing: 8) {
                        Text("Reps:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Stepper(
                            "\(exercise.targetReps ?? 0)",
                            value: Binding(
                                get: { exercise.targetReps ?? 0 },
                                set: { onUpdateReps($0 > 0 ? $0 : nil) }
                            ),
                            in: 0...100
                        )
                        .labelsHidden()
                        Text("\(exercise.targetReps ?? 0)")
                            .font(.subheadline)
                            .frame(minWidth: 20)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview("Create") {
    NavigationStack {
        TemplateFormView(template: nil)
    }
}

#Preview("Edit") {
    NavigationStack {
        TemplateFormView(
            template: MockTemplate(
                name: "Push Day",
                notes: "Chest focus",
                exercises: [
                    MockTemplateExercise(exerciseName: "Bench Press", exerciseType: .weightAndReps, order: 0, targetSets: 4, targetReps: 8),
                    MockTemplateExercise(exerciseName: "Dips", exerciseType: .bodyweightAndReps, order: 1, targetSets: 3, targetReps: 12),
                ]
            )
        )
    }
}
