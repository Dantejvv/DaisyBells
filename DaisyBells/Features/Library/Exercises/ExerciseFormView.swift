import SwiftUI

/// Create or edit an exercise
struct ExerciseFormView: View {
    @State private var viewModel: ExerciseFormViewModel

    init(viewModel: ExerciseFormViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private var canSave: Bool {
        !viewModel.name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        Form {
            Section("Exercise Info") {
                TextField("Name", text: $viewModel.name)

                Picker("Type", selection: $viewModel.type) {
                    ForEach(ExerciseType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .disabled(viewModel.isEditing)
            }

            Section("Categories") {
                ForEach(viewModel.availableCategories) { category in
                    Button {
                        viewModel.toggleCategory(category)
                    } label: {
                        HStack {
                            Text(category.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            if viewModel.selectedCategories.contains(where: { $0.id == category.id }) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }

            Section("Notes") {
                TextField("Form cues, tips, etc.", text: $viewModel.notes, axis: .vertical)
                    .lineLimit(4...8)
            }

            if viewModel.isEditing {
                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        Text("Exercise type cannot be changed after creation to preserve history accuracy.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
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
                .disabled(!canSave)
            }
        }
        .errorAlert(Binding(
            get: { viewModel.errorMessage },
            set: { viewModel.errorMessage = $0 }
        ))
        .task { await viewModel.load() }
    }
}
