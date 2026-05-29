import SwiftUI
import SwiftData

@MainActor
struct CategoryEditSheet: View {
    let category: SchemaV1.ExerciseCategory
    let viewModel: CategoryManagerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var showDeleteConfirmation = false
    @State private var nameFocused: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    BridgedTextField(
                        text: $name,
                        placeholder: "Category name",
                        isFocused: $nameFocused,
                        autocapitalization: .words,
                        textColor: .textPrimary,
                        onSubmit: { nameFocused = false }
                    )
                    .task { nameFocused = true }
                } header: {
                    Text("Name")
                        .foregroundStyle(Color.textSecondary)
                }
                .listRowBackground(Color.bgCard)

                Section {
                    LabeledContent("Exercises", value: "\(viewModel.exerciseCount(for: category))")
                        .foregroundStyle(Color.textPrimary)
                }
                .listRowBackground(Color.bgCard)

                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Category", systemImage: "trash")
                            .foregroundStyle(Color.destructive)
                    }
                }
                .listRowBackground(Color.bgCard)
            }
            .listStyle(.insetGrouped)
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(.hidden)
            .background(Color.bgPrimary)
            .tapToDismissKeyboard()
            .navigationTitle("Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.updateCategory(category, name: name)
                            dismiss()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .destructiveConfirmation(
                title: "Delete Category",
                message: "This will remove the category from all exercises. This action cannot be undone.",
                isPresented: $showDeleteConfirmation,
                onConfirm: {
                    Task {
                        await viewModel.deleteCategory(category)
                        dismiss()
                    }
                }
            )
        }
        .onAppear {
            name = category.name
        }
    }
}
