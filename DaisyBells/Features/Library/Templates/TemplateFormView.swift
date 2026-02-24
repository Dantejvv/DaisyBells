import SwiftUI
import SwiftData

@MainActor
struct TemplateFormView: View {
    @State var viewModel: TemplateFormViewModel
    @Environment(DependencyContainer.self) private var container

    var body: some View {
        List {
            nameAndNotesSection
            exercisesSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.bgPrimary)
        .navigationTitle(viewModel.isEditing ? "Edit Template" : "New Template")
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
        .sheet(isPresented: $viewModel.showExercisePicker) {
            NavigationStack {
                ExercisePickerSheet(
                    viewModel: ExercisePickerViewModel(
                        exerciseService: container.exerciseService,
                        categoryService: container.categoryService,
                        onSelect: { exerciseIds in
                            Task { await viewModel.onExercisesSelected(exerciseIds) }
                        }
                    )
                )
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Sections

    private var nameAndNotesSection: some View {
        Section {
            VStack(spacing: 0) {
                TextField("Template name", text: $viewModel.name)
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

    private var exercisesSection: some View {
        Section {
            ForEach(viewModel.exercises, id: \.id) { templateExercise in
                exerciseRow(templateExercise)
            }
            .onDelete { indexSet in
                guard let index = indexSet.first else { return }
                let exercise = viewModel.exercises[index]
                Task { await viewModel.removeExercise(exercise) }
            }
            .onMove { source, destination in
                Task { await viewModel.reorderExercises(from: source, to: destination) }
            }

            Button {
                viewModel.addExercise()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color.accent)
                    Text("Add Exercise")
                        .foregroundStyle(Color.accent)
                }
            }
        } header: {
            Text("Exercises")
                .foregroundStyle(Color.textSecondary)
        }
        .listRowBackground(Color.bgCard)
    }

    // MARK: - Exercise Row

    private func exerciseRow(_ templateExercise: SchemaV1.TemplateExercise) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: .spacing2xs) {
                Text(templateExercise.exercise?.name ?? "Unknown Exercise")
                    .foregroundStyle(Color.textPrimary)
                if let type = templateExercise.exercise?.type {
                    Text(type.displayName)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            Spacer()
        }
    }
}
