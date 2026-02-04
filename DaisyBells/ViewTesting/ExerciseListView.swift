import SwiftUI

/// Browse exercises with search and favorites filter
struct ExerciseListView: View {
    var filterCategory: MockCategory?

    @State private var exercises = MockExerciseData.exercises
    @State private var searchQuery = ""
    @State private var showFavoritesOnly = false

    private var filteredExercises: [MockExercise] {
        var result = exercises

        if let category = filterCategory {
            result = result.filter { $0.categoryNames.contains(category.name) }
        }

        if showFavoritesOnly {
            result = result.filter { $0.isFavorite }
        }

        if !searchQuery.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
        }

        return result
    }

    var body: some View {
        Group {
            if filteredExercises.isEmpty {
                if !searchQuery.isEmpty {
                    EmptyStateView(
                        systemImage: "magnifyingglass",
                        title: "No Results",
                        message: "No exercises match \"\(searchQuery)\"."
                    )
                } else if showFavoritesOnly {
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
                        // Add exercise action
                    }
                }
            } else {
                List(filteredExercises) { exercise in
                    NavigationLink {
                        ExerciseDetailView(exercise: exercise)
                    } label: {
                        ExerciseRow(exercise: exercise)
                    }
                }
            }
        }
        .navigationTitle(filterCategory?.name ?? "Exercises")
        .searchable(text: $searchQuery, prompt: "Search exercises")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        withAnimation {
                            showFavoritesOnly.toggle()
                        }
                    } label: {
                        Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                            .foregroundStyle(showFavoritesOnly ? .yellow : .primary)
                    }

                    NavigationLink {
                        ExerciseFormView(exercise: nil)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

private struct ExerciseRow: View {
    let exercise: MockExercise

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(exercise.name)
                        .font(.body)

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

#Preview("All Exercises") {
    NavigationStack {
        ExerciseListView()
    }
}

#Preview("Filtered by Category") {
    NavigationStack {
        ExerciseListView(filterCategory: MockCategory(name: "Upper Body", exerciseCount: 6))
    }
}
