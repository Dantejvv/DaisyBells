import SwiftUI
import SwiftData

@MainActor
struct CategoryListView: View {
    @State var viewModel: CategoryListViewModel
    @State private var showNewCategoryAlert = false
    @State private var newCategoryName = ""
    @State private var renamingCategory: SchemaV1.ExerciseCategory?
    @State private var renameCategoryName = ""

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingSpinnerView()
            } else if viewModel.categories.isEmpty {
                EmptyStateView(
                    icon: "folder",
                    title: "No Categories Yet",
                    message: "Create a category to organize your exercises."
                ) {
                    Button("Add Category") {
                        newCategoryName = ""
                        showNewCategoryAlert = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accent)
                }
            } else {
                categoryList
            }
        }
        .task { await viewModel.loadCategories() }
        .errorAlert(errorMessage: $viewModel.errorMessage)
        .alert("New Category", isPresented: $showNewCategoryAlert) {
            TextField("Category name", text: $newCategoryName)
            Button("Cancel", role: .cancel) {}
            Button("Add") {
                let trimmed = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                Task { await viewModel.createCategory(name: String(trimmed.prefix(20))) }
            }
        } message: {
            Text("Enter a name for the new category.")
        }
        .alert("Rename Category", isPresented: Binding(
            get: { renamingCategory != nil },
            set: { if !$0 { renamingCategory = nil } }
        )) {
            TextField("Category name", text: $renameCategoryName)
            Button("Cancel", role: .cancel) {
                renamingCategory = nil
            }
            Button("Rename") {
                let trimmed = renameCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty, let category = renamingCategory else { return }
                Task { await viewModel.updateCategory(category, name: String(trimmed.prefix(20))) }
                renamingCategory = nil
            }
        } message: {
            Text("Enter a new name for the category.")
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    newCategoryName = ""
                    showNewCategoryAlert = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }

    // MARK: - Category List

    private var categoryList: some View {
        List {
            allExercisesRow

            Section {
                ForEach(viewModel.categories, id: \.id) { category in
                    categoryRow(category)
                }
                .onMove { source, destination in
                    Task { await viewModel.reorderCategories(from: source, to: destination) }
                }
            } header: {
                Text("Categories")
                    .foregroundStyle(Color.textSecondary)
            }
            .listRowBackground(Color.bgCard)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.bgPrimary)
    }

    private var allExercisesRow: some View {
        Button {
            viewModel.selectAllExercises()
        } label: {
            HStack {
                Image(systemName: "dumbbell")
                    .foregroundStyle(Color.accent)
                Text("All Exercises")
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .listRowBackground(Color.bgCard)
    }

    private func categoryRow(_ category: SchemaV1.ExerciseCategory) -> some View {
        Button {
            viewModel.selectCategory(category)
        } label: {
            HStack {
                Text(category.name)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text("\(category.exercises.count)")
                    .foregroundStyle(Color.textSecondary)
                    .font(.subheadline)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                Task { await viewModel.deleteCategory(category) }
            } label: {
                Label("Delete", systemImage: "trash")
            }
            Button {
                renameCategoryName = category.name
                renamingCategory = category
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            .tint(.accent)
        }
    }
}
