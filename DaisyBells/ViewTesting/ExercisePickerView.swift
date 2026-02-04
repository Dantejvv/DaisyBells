import SwiftUI

/// Sheet to select an exercise (used by template form and active workout)
struct ExercisePickerView: View {
    let onSelect: (MockExercise) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var exercises = MockExerciseData.exercises.filter { !$0.isArchived }
    @State private var searchQuery = ""
    @State private var selectedCategory: String?

    private let categories = ["All", "Upper Body", "Lower Body", "Core", "Cardio"]

    private var filteredExercises: [MockExercise] {
        var result = exercises

        if let category = selectedCategory, category != "All" {
            result = result.filter { $0.categoryNames.contains(category) }
        }

        if !searchQuery.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
        }

        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            // Category filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.self) { category in
                        CategoryChip(
                            title: category,
                            isSelected: selectedCategory == category || (selectedCategory == nil && category == "All")
                        ) {
                            withAnimation {
                                selectedCategory = category == "All" ? nil : category
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .background(.bar)

            Divider()

            if filteredExercises.isEmpty {
                if !searchQuery.isEmpty {
                    EmptyStateView(
                        systemImage: "magnifyingglass",
                        title: "No Results",
                        message: "No exercises match \"\(searchQuery)\"."
                    )
                } else {
                    EmptyStateView(
                        systemImage: "dumbbell",
                        title: "No Exercises",
                        message: "No exercises in this category."
                    )
                }
            } else {
                List(filteredExercises) { exercise in
                    Button {
                        onSelect(exercise)
                        dismiss()
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
        .searchable(text: $searchQuery, prompt: "Search exercises")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
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

#Preview {
    NavigationStack {
        ExercisePickerView { exercise in
            print("Selected: \(exercise.name)")
        }
    }
}
