import SwiftUI
import SwiftData

@MainActor
struct ExerciseFormView: View {
    @State var viewModel: ExerciseFormViewModel
    @FocusState private var nameFocused: Bool
    @FocusState private var notesFocused: Bool

    var body: some View {
        List {
            nameAndNotesSection
            dropdownRow
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .scrollContentBackground(.hidden)
        .background(Color.bgPrimary)
        .tapToDismissKeyboard()
        .navigationTitle(viewModel.isEditing ? "Edit Exercise" : "New Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    viewModel.cancel()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await viewModel.save() }
                }
                .disabled(!viewModel.canSave)
            }
        }
        .task { await viewModel.load() }
        .onChange(of: viewModel.name) {
            Task { await viewModel.checkForDuplicate() }
        }
        .onChange(of: viewModel.type) {
            Task { await viewModel.checkForDuplicate() }
        }
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
    }

    // MARK: - Sections

    private var nameAndNotesSection: some View {
        Section {
            VStack(spacing: 0) {
                TextField("Exercise name", text: $viewModel.name)
                    .focused($nameFocused)
                    .submitLabel(.done)
                    .textInputAutocapitalization(.words)
                    .onSubmit { nameFocused = false }
                    .keyboardDoneToolbar(isFocused: nameFocused) { nameFocused = false }
                    .foregroundStyle(Color.textPrimary)
                    .padding(.bottom, .spacingSm)
                    .task {
                        if !viewModel.isEditing { nameFocused = true }
                    }
                if let duplicate = viewModel.duplicateExercise {
                    HStack(spacing: .spacingXs) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(duplicateMessage(for: duplicate))
                        Spacer(minLength: 0)
                    }
                    .font(.caption)
                    .foregroundStyle(Color.warning)
                    .padding(.bottom, .spacingSm)
                }
                Divider()
                TextField("Notes", text: $viewModel.notes, axis: .vertical)
                    .focused($notesFocused)
                    .textInputAutocapitalization(.sentences)
                    .keyboardDoneToolbar(isFocused: notesFocused) { notesFocused = false }
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(3...6)
                    .padding(.top, .spacingMd)
            }
        }
        .listRowBackground(Color.bgCard)
    }

    private func duplicateMessage(for duplicate: SchemaV1.Exercise) -> String {
        let archivedSuffix = duplicate.isArchived ? " (archived)" : ""
        return "Already exists as \(duplicate.type.displayName)\(archivedSuffix)"
    }

    private var dropdownRow: some View {
        Section {
            HStack(spacing: .spacingSm) {
                categoryMenu
                typeMenu
            }
            .listRowInsets(EdgeInsets(top: .spacingSm, leading: .spacingBase, bottom: .spacingSm, trailing: .spacingBase))
        }
        .listRowBackground(Color.bgCard)
    }

    // MARK: - Category Menu

    private var categoryMenu: some View {
        Menu {
            if viewModel.availableCategories.isEmpty {
                Text("No categories")
            } else {
                ForEach(viewModel.availableCategories, id: \.id) { category in
                    Button {
                        viewModel.toggleCategory(category)
                    } label: {
                        if viewModel.selectedCategories.contains(where: { $0.id == category.id }) {
                            Label(category.name, systemImage: "checkmark")
                        } else {
                            Text(category.name)
                        }
                    }
                }
            }
            Divider()
            Button {
                viewModel.showNewCategoryAlert = true
            } label: {
                Label("New Category", systemImage: "plus")
            }
        } label: {
            dropdownLabel(
                title: categoryTitle,
                isActive: !viewModel.selectedCategories.isEmpty
            )
        }
        .frame(maxWidth: .infinity)
    }

    private var categoryTitle: String {
        if viewModel.selectedCategories.isEmpty {
            return "Category"
        } else if viewModel.selectedCategories.count == 1 {
            return viewModel.selectedCategories[0].name
        } else {
            return "\(viewModel.selectedCategories.count) Categories"
        }
    }

    // MARK: - Type Menu

    private var typeMenu: some View {
        Menu {
            ForEach(ExerciseType.allCases, id: \.self) { type in
                Button {
                    viewModel.type = type
                } label: {
                    if viewModel.type == type {
                        Label(type.displayName, systemImage: "checkmark")
                    } else {
                        Text(type.displayName)
                    }
                }
            }
        } label: {
            dropdownLabel(
                title: viewModel.type.displayName,
                isActive: true
            )
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Dropdown Label

    private func dropdownLabel(title: String, isActive: Bool) -> some View {
        HStack(spacing: .spacingXs) {
            Text(title)
                .font(.subheadline)
                .lineLimit(1)
            Image(systemName: "chevron.up.chevron.down")
                .font(.caption2)
        }
        .padding(.horizontal, .spacingSm)
        .padding(.vertical, .spacingSm)
        .frame(maxWidth: .infinity)
        .foregroundStyle(isActive ? Color.accent : Color.textSecondary)
        .background(isActive ? Color.accentBg : Color.bgCardHover)
        .clipShape(RoundedRectangle(cornerRadius: .radiusSm))
        .overlay(
            RoundedRectangle(cornerRadius: .radiusSm)
                .stroke(isActive ? Color.accent.opacity(0.3) : Color.borderSubtle, lineWidth: 1)
        )
    }
}
