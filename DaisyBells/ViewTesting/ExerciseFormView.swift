import SwiftUI

/// Create or edit an exercise
struct ExerciseFormView: View {
    let exercise: MockExercise?

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var type: MockExerciseType
    @State private var notes: String
    @State private var selectedCategories: Set<String>
    @State private var errorMessage: String?

    private var isEditing: Bool { exercise != nil }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    private let availableCategories = ["Upper Body", "Lower Body", "Core", "Cardio", "Olympic Lifts"]

    init(exercise: MockExercise?) {
        self.exercise = exercise
        _name = State(initialValue: exercise?.name ?? "")
        _type = State(initialValue: exercise?.type ?? .weightAndReps)
        _notes = State(initialValue: exercise?.notes ?? "")
        _selectedCategories = State(initialValue: Set(exercise?.categoryNames ?? []))
    }

    var body: some View {
        Form {
            Section("Exercise Info") {
                TextField("Name", text: $name)

                Picker("Type", selection: $type) {
                    ForEach(MockExerciseType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
            }

            Section("Categories") {
                ForEach(availableCategories, id: \.self) { category in
                    Button {
                        if selectedCategories.contains(category) {
                            selectedCategories.remove(category)
                        } else {
                            selectedCategories.insert(category)
                        }
                    } label: {
                        HStack {
                            Text(category)
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedCategories.contains(category) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }

            Section("Notes") {
                TextField("Form cues, tips, etc.", text: $notes, axis: .vertical)
                    .lineLimit(4...8)
            }

            if isEditing {
                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        Text("Exercise type cannot be changed after creation to preserve history accuracy.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(isEditing ? "Edit Exercise" : "New Exercise")
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
        .errorAlert($errorMessage)
    }

    private func save() {
        guard canSave else {
            errorMessage = "Please enter an exercise name."
            return
        }
        // Save logic would go here
        dismiss()
    }
}

#Preview("Create") {
    NavigationStack {
        ExerciseFormView(exercise: nil)
    }
}

#Preview("Edit") {
    NavigationStack {
        ExerciseFormView(
            exercise: MockExercise(
                name: "Bench Press",
                type: .weightAndReps,
                notes: "Keep shoulders back",
                categoryNames: ["Upper Body"]
            )
        )
    }
}
