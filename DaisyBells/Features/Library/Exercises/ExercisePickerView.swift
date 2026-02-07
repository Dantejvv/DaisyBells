import SwiftUI
import SwiftData

/// Sheet to select an exercise (used by template form and active workout)
struct ExercisePickerView: View {
    @State private var viewModel: ExercisePickerViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: ExercisePickerViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Category filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    CategoryChip(
                        title: "All",
                        isSelected: viewModel.selectedCategoryId == nil
                    ) {
                        withAnimation {
                            viewModel.filterByCategory(nil)
                        }
                    }

                    ForEach(viewModel.categories) { category in
                        CategoryChip(
                            title: category.name,
                            isSelected: viewModel.selectedCategoryId == category.persistentModelID
                        ) {
                            withAnimation {
                                viewModel.filterByCategory(category.persistentModelID)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .background(.bar)

            Divider()

            if viewModel.exercises.isEmpty {
                if !viewModel.searchQuery.isEmpty {
                    EmptyStateView(
                        systemImage: "magnifyingglass",
                        title: "No Results",
                        message: "No exercises match \"\(viewModel.searchQuery)\"."
                    )
                } else {
                    EmptyStateView(
                        systemImage: "dumbbell",
                        title: "No Exercises",
                        message: "No exercises in this category."
                    )
                }
            } else {
                List(viewModel.exercises) { exercise in
                    Button {
                        viewModel.selectExercise(exercise)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text(exercise.name)
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

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Select Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: Binding(
            get: { viewModel.searchQuery },
            set: { viewModel.search(query: $0) }
        ), prompt: "Search exercises")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
            if shouldDismiss { dismiss() }
        }
        .task { await viewModel.loadExercises() }
    }
}

private struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}
