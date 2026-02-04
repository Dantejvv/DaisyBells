import SwiftUI

/// View exercise details with options to edit, delete, or archive
struct ExerciseDetailView: View {
    let exercise: MockExercise

    @Environment(\.dismiss) private var dismiss
    @State private var isFavorite: Bool
    @State private var deleteConfig: ConfirmationDialogConfig?

    init(exercise: MockExercise) {
        self.exercise = exercise
        _isFavorite = State(initialValue: exercise.isFavorite)
    }

    // Mock: determine if exercise has history (affects delete behavior)
    private var hasHistory: Bool { true }

    var body: some View {
        List {
            Section {
                DetailRow(label: "Type", value: exercise.type.displayName)

                if !exercise.categoryNames.isEmpty {
                    DetailRow(label: "Categories", value: exercise.categoryNames.joined(separator: ", "))
                }

                if let notes = exercise.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(notes)
                    }
                    .padding(.vertical, 4)
                }
            }

            if exercise.isArchived {
                Section {
                    HStack {
                        Image(systemName: "archivebox")
                            .foregroundStyle(.secondary)
                        Text("This exercise is archived and won't appear in exercise pickers.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    if hasHistory {
                        deleteConfig = ConfirmationDialogConfig(
                            title: "Archive Exercise?",
                            message: "This exercise has workout history. It will be archived instead of deleted. Archived exercises won't appear in pickers but history is preserved.",
                            confirmTitle: "Archive"
                        ) {
                            dismiss()
                        }
                    } else {
                        deleteConfig = ConfirmationDialogConfig(
                            title: "Delete Exercise?",
                            message: "This action cannot be undone.",
                            confirmTitle: "Delete"
                        ) {
                            dismiss()
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: hasHistory ? "archivebox" : "trash")
                        Text(hasHistory ? "Archive Exercise" : "Delete Exercise")
                    }
                }
            }
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        withAnimation {
                            isFavorite.toggle()
                        }
                    } label: {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .foregroundStyle(isFavorite ? .yellow : .primary)
                    }

                    NavigationLink {
                        ExerciseFormView(exercise: exercise)
                    } label: {
                        Text("Edit")
                    }
                }
            }
        }
        .confirmationDialog($deleteConfig)
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
    }
}

#Preview("With Notes") {
    NavigationStack {
        ExerciseDetailView(
            exercise: MockExercise(
                name: "Bench Press",
                type: .weightAndReps,
                notes: "Keep shoulders back and down. Arch back slightly. Drive feet into floor.",
                isFavorite: true,
                categoryNames: ["Upper Body", "Push"]
            )
        )
    }
}

#Preview("Archived") {
    NavigationStack {
        ExerciseDetailView(
            exercise: MockExercise(
                name: "Leg Press",
                type: .weightAndReps,
                isArchived: true,
                categoryNames: ["Lower Body"]
            )
        )
    }
}

#Preview("Minimal") {
    NavigationStack {
        ExerciseDetailView(
            exercise: MockExercise(
                name: "Box Jumps",
                type: .reps
            )
        )
    }
}
