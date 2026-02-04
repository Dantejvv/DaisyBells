import SwiftUI

/// View template details, start workout, duplicate, or delete
struct TemplateDetailView: View {
    let template: MockTemplate

    @Environment(\.dismiss) private var dismiss
    @State private var deleteConfig: ConfirmationDialogConfig?
    @State private var showingActiveWorkout = false

    var body: some View {
        List {
            if let notes = template.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Exercises") {
                if template.exercises.isEmpty {
                    Text("No exercises added")
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
                    ForEach(template.exercises) { exercise in
                        TemplateExerciseRow(exercise: exercise)
                    }
                }
            }

            Section {
                Button {
                    showingActiveWorkout = true
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Workout")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            Section {
                Button {
                    // Duplicate action
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("Duplicate Template")
                    }
                }

                Button(role: .destructive) {
                    deleteConfig = ConfirmationDialogConfig(
                        title: "Delete Template?",
                        message: "This template will be permanently deleted. Your workout history will not be affected.",
                        confirmTitle: "Delete"
                    ) {
                        dismiss()
                    }
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Template")
                    }
                }
            }
        }
        .navigationTitle(template.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    TemplateFormView(template: template)
                } label: {
                    Text("Edit")
                }
            }
        }
        .confirmationDialog($deleteConfig)
        .fullScreenCover(isPresented: $showingActiveWorkout) {
            NavigationStack {
                ActiveWorkoutView(templateName: template.name, exercises: template.exercises)
            }
        }
    }
}

private struct TemplateExerciseRow: View {
    let exercise: MockTemplateExercise

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.exerciseName)
                    .font(.body)

                Text(exercise.exerciseType.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let sets = exercise.targetSets, let reps = exercise.targetReps {
                Text("\(sets) × \(reps)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if let sets = exercise.targetSets {
                Text("\(sets) sets")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview("Full Template") {
    NavigationStack {
        TemplateDetailView(
            template: MockTemplate(
                name: "Push Day",
                notes: "Focus on progressive overload. Rest 2-3 min between sets.",
                exercises: [
                    MockTemplateExercise(exerciseName: "Bench Press", exerciseType: .weightAndReps, order: 0, targetSets: 4, targetReps: 8),
                    MockTemplateExercise(exerciseName: "Overhead Press", exerciseType: .weightAndReps, order: 1, targetSets: 3, targetReps: 10),
                    MockTemplateExercise(exerciseName: "Dips", exerciseType: .bodyweightAndReps, order: 2, targetSets: 3, targetReps: 12),
                ]
            )
        )
    }
}

#Preview("Empty Template") {
    NavigationStack {
        TemplateDetailView(
            template: MockTemplate(name: "New Template")
        )
    }
}
