import SwiftUI

/// List of exercise categories with add and delete functionality
struct CategoryListView: View {
    @State private var viewModel: CategoryListViewModel
    @State private var isAddingCategory = false
    @State private var newCategoryName = ""
    @State private var deleteConfig: ConfirmationDialogConfig?

    init(viewModel: CategoryListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingSpinnerView(message: "Loading categories...")
            } else {
                List {
                    ForEach(viewModel.categories) { category in
                        Button {
                            viewModel.selectCategory(category)
                        } label: {
                            CategoryRow(category: category)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Delete", role: .destructive) {
                                deleteConfig = ConfirmationDialogConfig(
                                    title: "Delete \"\(category.name)\"?",
                                    message: "Exercises in this category will not be deleted.",
                                    confirmTitle: "Delete"
                                ) {
                                    Task { await viewModel.deleteCategory(category) }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isAddingCategory = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("New Category", isPresented: $isAddingCategory) {
            TextField("Category name", text: $newCategoryName)
            Button("Cancel", role: .cancel) {
                newCategoryName = ""
            }
            Button("Add") {
                if !newCategoryName.isEmpty {
                    Task {
                        await viewModel.createCategory(name: newCategoryName)
                        newCategoryName = ""
                    }
                }
            }
        }
        .confirmationDialog($deleteConfig)
        .errorAlert(Binding(
            get: { viewModel.errorMessage },
            set: { viewModel.errorMessage = $0 }
        ))
        .task { await viewModel.loadCategories() }
    }
}

private struct CategoryRow: View {
    let category: SchemaV1.ExerciseCategory

    var body: some View {
        HStack {
            Text(category.name)
                .foregroundStyle(.primary)
            Spacer()
            Text("\(category.exercises.count)")
                .foregroundStyle(.secondary)
        }
    }
}
