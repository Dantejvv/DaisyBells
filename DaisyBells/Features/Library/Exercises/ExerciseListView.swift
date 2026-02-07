import SwiftUI

/// Browse exercises with search and favorites filter
struct ExerciseListView: View {
    @State private var viewModel: ExerciseListViewModel

    init(viewModel: ExerciseListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingSpinnerView(message: "Loading exercises...")
            } else if viewModel.exercises.isEmpty {
                if !viewModel.searchQuery.isEmpty {
                    EmptyStateView(
                        systemImage: "magnifyingglass",
                        title: "No Results",
                        message: "No exercises match \"\(viewModel.searchQuery)\"."
                    )
                } else if viewModel.showFavoritesOnly {
                    EmptyStateView(
                        systemImage: "star",
                        title: "No Favorites",
                        message: "Star an exercise to add it to your favorites."
                    )
                } else {
                    EmptyStateView(
                        systemImage: "dumbbell",
                        title: "No Exercises",
                        message: "Add your first exercise to get started.",
                        buttonTitle: "Add Exercise"
                    ) {
                        viewModel.createExercise()
                    }
                }
            } else {
                List(viewModel.exercises) { exercise in
                    Button {
                        viewModel.selectExercise(exercise)
                    } label: {
                        ExerciseRow(exercise: exercise)
                    }
                }
            }
        }
        .navigationTitle(viewModel.selectedCategoryId != nil ? "Exercises" : "Exercises")
        .searchable(text: Binding(
            get: { viewModel.searchQuery },
            set: { newValue in
                Task { await viewModel.search(query: newValue) }
            }
        ), prompt: "Search exercises")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        Task { await viewModel.toggleFavoritesFilter() }
                    } label: {
                        Image(systemName: viewModel.showFavoritesOnly ? "star.fill" : "star")
                            .foregroundStyle(viewModel.showFavoritesOnly ? .yellow : .primary)
                    }

                    Button {
                        viewModel.createExercise()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .errorAlert(Binding(
            get: { viewModel.errorMessage },
            set: { viewModel.errorMessage = $0 }
        ))
        .task { await viewModel.loadExercises() }
    }
}

private struct ExerciseRow: View {
    let exercise: SchemaV1.Exercise

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(exercise.name)
                        .font(.body)
                        .foregroundStyle(.primary)

                    if exercise.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }

                Text(exercise.type.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if exercise.isArchived {
                Text("Archived")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.secondary.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 2)
    }
}
