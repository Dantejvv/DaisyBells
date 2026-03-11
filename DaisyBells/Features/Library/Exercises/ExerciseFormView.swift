import SwiftUI
import SwiftData

@MainActor
struct ExerciseFormView: View {
    @State var viewModel: ExerciseFormViewModel

    var body: some View {
        List {
            nameAndNotesSection
            dropdownRow
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.bgPrimary)
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
                .disabled(viewModel.isSaving || viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .task { await viewModel.load() }
        .errorAlert(errorMessage: $viewModel.errorMessage)
    }

    // MARK: - Sections

    private var nameAndNotesSection: some View {
        Section {
            VStack(spacing: 0) {
                TextField("Exercise name", text: $viewModel.name)
                    .foregroundStyle(Color.textPrimary)
                    .padding(.bottom, .spacingSm)
                Divider()
                TextField("Optional notes.......", text: $viewModel.notes, axis: .vertical)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(3...6)
                    .padding(.top, .spacingMd)
            }
        }
        .listRowBackground(Color.bgCard)
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
