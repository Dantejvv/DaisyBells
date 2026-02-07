import SwiftUI

/// Create or edit a workout template
struct TemplateFormView: View {
    @State private var viewModel: TemplateFormViewModel

    init(viewModel: TemplateFormViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private var canSave: Bool {
        !viewModel.name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        Form {
            Section("Template Info") {
                TextField("Name", text: $viewModel.name)
                TextField("Notes (optional)", text: $viewModel.notes, axis: .vertical)
                    .lineLimit(2...4)
            }

            Section {
                if viewModel.exercises.isEmpty {
                    Text("No exercises added")
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
                    ForEach(viewModel.exercises) { exercise in
                        TemplateExerciseEditRow(
                            exercise: exercise,
                            onUpdateSets: { newSets in
                                Task {
                                    await viewModel.updateTargets(
                                        exercise: exercise,
                                        sets: newSets,
                                        reps: exercise.targetReps
                                    )
                                }
                            },
                            onUpdateReps: { newReps in
                                Task {
                                    await viewModel.updateTargets(
                                        exercise: exercise,
                                        sets: exercise.targetSets,
                                        reps: newReps
                                    )
                                }
                            }
                        )
                    }
                    .onDelete { indexSet in
                        if let first = indexSet.first {
                            let exercise = viewModel.exercises[first]
                            Task { await viewModel.removeExercise(exercise) }
                        }
                    }
                    .onMove { from, to in
                        Task { await viewModel.reorderExercises(from: from, to: to) }
                    }
                }

                Button {
                    viewModel.addExercise()
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
                    if !viewModel.exercises.isEmpty {
                        EditButton()
                            .font(.caption)
                    }
                }
            }
        }
        .navigationTitle(viewModel.isEditing ? "Edit Template" : "New Template")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    viewModel.cancel()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await viewModel.save() }
                }
                .disabled(!canSave)
            }
        }
        .errorAlert(Binding(
            get: { viewModel.errorMessage },
            set: { viewModel.errorMessage = $0 }
        ))
        .task { await viewModel.load() }
    }
}

private struct TemplateExerciseEditRow: View {
    let exercise: SchemaV1.TemplateExercise
    let onUpdateSets: (Int?) -> Void
    let onUpdateReps: (Int?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(exercise.exercise?.name ?? "Unknown")
                    .font(.body)
                Spacer()
                Text(exercise.exercise?.type.displayName ?? "")
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

                if let exerciseType = exercise.exercise?.type,
                   exerciseType == .weightAndReps || exerciseType == .bodyweightAndReps || exerciseType == .reps {
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
