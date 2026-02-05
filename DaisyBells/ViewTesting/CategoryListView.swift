import SwiftUI

/// List of exercise categories with add, edit, and delete functionality
struct CategoryListView: View {
    @State private var categories = MockData.categories
    @State private var isAddingCategory = false
    @State private var newCategoryName = ""
    @State private var editingCategory: MockCategory?
    @State private var editingCategoryName = ""
    @State private var deleteConfig: ConfirmationDialogConfig?

    var body: some View {
        List {
            ForEach(categories) { category in
                NavigationLink {
                    // Navigate to exercises filtered by category
                    ExerciseListView(filterCategory: category)
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
                            withAnimation {
                                categories.removeAll { $0.id == category.id }
                            }
                        }
                    }
                    Button("Edit") {
                        editingCategory = category
                        editingCategoryName = category.name
                    }
                    .tint(.blue)
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
                    let newCategory = MockCategory(name: newCategoryName)
                    withAnimation {
                        categories.append(newCategory)
                    }
                    newCategoryName = ""
                }
            }
        }
        .alert("Edit Category", isPresented: Binding(
            get: { editingCategory != nil },
            set: { if !$0 { editingCategory = nil } }
        )) {
            TextField("Category name", text: $editingCategoryName)
            Button("Cancel", role: .cancel) {
                editingCategory = nil
            }
            Button("Save") {
                if let index = categories.firstIndex(where: { $0.id == editingCategory?.id }) {
                    categories[index].name = editingCategoryName
                }
                editingCategory = nil
            }
        }
        .confirmationDialog($deleteConfig)
    }
}

private struct CategoryRow: View {
    let category: MockCategory

    var body: some View {
        HStack {
            Text(category.name)
            Spacer()
            Text("\(category.exerciseCount)")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        CategoryListView()
    }
}
