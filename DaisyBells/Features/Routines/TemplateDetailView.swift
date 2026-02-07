import SwiftUI

/// View template details, start workout, duplicate, or delete
struct TemplateDetailView: View {
    @State private var viewModel: TemplateDetailViewModel
    @State private var deleteConfig: ConfirmationDialogConfig?

    init(viewModel: TemplateDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingSpinnerView(message: "Loading template...")
            } else if let template = viewModel.template {
                templateContent(template)
            }
        }
        .errorAlert(Binding(
            get: { viewModel.errorMessage },
            set: { viewModel.errorMessage = $0 }
        ))
        .task { await viewModel.loadTemplate() }
    }

    @ViewBuilder
    private func templateContent(_ template: SchemaV1.WorkoutTemplate) -> some View {
        List {
            if let notes = template.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Exercises") {
                if viewModel.exercises.isEmpty {
                    Text("No exercises added")
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
                    ForEach(viewModel.exercises) { exercise in
                        TemplateExerciseRow(exercise: exercise)
                    }
                }
            }

            Section {
                Button {
                    Task { await viewModel.startWorkout() }
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
                    Task { await viewModel.duplicateTemplate() }
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
                        Task { await viewModel.deleteTemplate() }
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
                Button("Edit") {
                    viewModel.editTemplate()
                }
            }
        }
        .confirmationDialog($deleteConfig)
    }
}

private struct TemplateExerciseRow: View {
    let exercise: SchemaV1.TemplateExercise

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.exercise?.name ?? "Unknown")
                    .font(.body)

                Text(exercise.exercise?.type.displayName ?? "")
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
