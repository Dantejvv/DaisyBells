import SwiftUI
import SwiftData

@MainActor
struct CategoryManagerSheet: View {
    @State var viewModel: CategoryManagerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: SchemaV1.ExerciseCategory?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    LoadingSpinnerView()
                } else if viewModel.categories.isEmpty {
                    EmptyStateView(
                        icon: "folder",
                        title: "No Categories",
                        message: "Add a category to organize your exercises."
                    ) {
                        Button("Add Category") {
                            viewModel.showNewCategoryAlert = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.accent)
                    }
                } else {
                    categoryList
                }
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showNewCategoryAlert = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task { await viewModel.loadCategories() }
            .errorAlert(errorMessage: $viewModel.errorMessage)
            .alert("New Category", isPresented: $viewModel.showNewCategoryAlert) {
                TextField("Category name", text: $viewModel.newCategoryName)
                    .submitLabel(.done)
                    .textInputAutocapitalization(.words)
                    .onSubmit { Task { await viewModel.createCategory() } }
                Button("Cancel", role: .cancel) {
                    viewModel.newCategoryName = ""
                }
                Button("Add") {
                    Task { await viewModel.createCategory() }
                }
            } message: {
                Text("Enter a name for the new category.")
            }
            .sheet(item: $selectedCategory) { category in
                CategoryEditSheet(
                    category: category,
                    viewModel: viewModel
                )
            }
        }
    }

    // MARK: - Category List

    private var categoryList: some View {
        List {
            ForEach(viewModel.categories, id: \.id) { category in
                Button {
                    selectedCategory = category
                } label: {
                    HStack {
                        Text(category.name)
                            .foregroundStyle(Color.textPrimary)
                        Spacer()
                        Text("\(viewModel.exerciseCount(for: category))")
                            .foregroundStyle(Color.textSecondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color.textTertiary)
                    }
                }
            }
            .listRowBackground(Color.bgCard)
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .scrollContentBackground(.hidden)
        .background(Color.bgPrimary)
        .tapToDismissKeyboard()
    }
}
