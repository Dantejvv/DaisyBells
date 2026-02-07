import SwiftUI

/// View exercise details with options to edit, delete, or archive
struct ExerciseDetailView: View {
    @State private var viewModel: ExerciseDetailViewModel
    @State private var deleteConfig: ConfirmationDialogConfig?

    init(viewModel: ExerciseDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingSpinnerView(message: "Loading exercise...")
            } else if let exercise = viewModel.exercise {
                exerciseContent(exercise)
            }
        }
        .errorAlert(Binding(
            get: { viewModel.errorMessage },
            set: { viewModel.errorMessage = $0 }
        ))
        .task { await viewModel.loadExercise() }
    }

    @ViewBuilder
    private func exerciseContent(_ exercise: SchemaV1.Exercise) -> some View {
        List {
            Section {
                DetailRow(label: "Type", value: exercise.type.displayName)

                if !exercise.categories.isEmpty {
                    DetailRow(
                        label: "Categories",
                        value: exercise.categories.map { $0.name }.joined(separator: ", ")
                    )
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
                    let hasHistory = !viewModel.canDelete
                    if hasHistory {
                        deleteConfig = ConfirmationDialogConfig(
                            title: "Archive Exercise?",
                            message: "This exercise has workout history. It will be archived instead of deleted. Archived exercises won't appear in pickers but history is preserved.",
                            confirmTitle: "Archive"
                        ) {
                            Task { await viewModel.deleteExercise() }
                        }
                    } else {
                        deleteConfig = ConfirmationDialogConfig(
                            title: "Delete Exercise?",
                            message: "This action cannot be undone.",
                            confirmTitle: "Delete"
                        ) {
                            Task { await viewModel.deleteExercise() }
                        }
                    }
                } label: {
                    let hasHistory = !viewModel.canDelete
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
                        Task { await viewModel.toggleFavorite() }
                    } label: {
                        Image(systemName: exercise.isFavorite ? "star.fill" : "star")
                            .foregroundStyle(exercise.isFavorite ? .yellow : .primary)
                    }

                    Button("Edit") {
                        viewModel.editExercise()
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
