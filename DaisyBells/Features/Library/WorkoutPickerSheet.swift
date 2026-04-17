import SwiftUI
import SwiftData

@MainActor
struct WorkoutPickerSheet: View {
    @State var viewModel: WorkoutPickerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            searchBar
                .padding(.horizontal, .spacingBase)
                .padding(.bottom, .spacingXs)

            Group {
                if viewModel.isLoading {
                    LoadingSpinnerView()
                } else if viewModel.templates.isEmpty {
                    EmptyStateView(
                        icon: "doc.text",
                        title: "No Templates",
                        message: viewModel.searchQuery.isEmpty
                            ? "Create workout templates in the Library first."
                            : "No templates match your search."
                    )
                } else {
                    templateList
                }
            }
        }
        .navigationTitle("Select Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .task { await viewModel.loadTemplates() }
        .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
            if shouldDismiss { dismiss() }
        }
        .background(Color.bgPrimary)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: .spacingSm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.textTertiary)
            TextField("Search templates", text: Binding(
                get: { viewModel.searchQuery },
                set: { viewModel.search(query: $0) }
            ))
            .foregroundStyle(Color.textPrimary)
            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.search(query: "")
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.textTertiary)
                }
            }
        }
        .padding(.horizontal, .spacingSm)
        .padding(.vertical, .spacingSm)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: .radiusMd))
    }

    // MARK: - Template List

    private var templateList: some View {
        List {
            ForEach(viewModel.templates, id: \.id) { template in
                Button {
                    viewModel.selectTemplate(template)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: .spacing2xs) {
                            Text(template.name)
                                .foregroundStyle(Color.textPrimary)
                            Text("\(template.templateExercises.count) exercise\(template.templateExercises.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }
                        Spacer()
                    }
                }
            }
            .listRowBackground(Color.bgCard)
        }
        .listStyle(.insetGrouped)
        .contentMargins(.top, .spacingXs)
        .scrollContentBackground(.hidden)
        .background(Color.bgPrimary)
    }
}

// MARK: - Preview

private struct PreviewWorkoutPickerSheet: View {
    var body: some View {
        NavigationStack {
            WorkoutPickerSheet(
                viewModel: WorkoutPickerViewModel(
                    templateService: PreviewTemplateService(),
                    onSelect: { _ in }
                )
            )
        }
    }
}

private final class PreviewTemplateService: TemplateServiceProtocol {
    func fetchAll() async throws -> [SchemaV1.WorkoutTemplate] { [] }
    func fetch(id: UUID) async throws -> SchemaV1.WorkoutTemplate { fatalError() }
    func fetch(by persistentId: PersistentIdentifier) -> SchemaV1.WorkoutTemplate? { nil }
    func search(query: String) async throws -> [SchemaV1.WorkoutTemplate] { [] }
    func create(name: String) async throws -> SchemaV1.WorkoutTemplate { fatalError() }
    func update(_ template: SchemaV1.WorkoutTemplate) async throws {}
    func duplicate(_ template: SchemaV1.WorkoutTemplate) async throws -> SchemaV1.WorkoutTemplate { fatalError() }
    func delete(_ template: SchemaV1.WorkoutTemplate) async throws {}
    func addExercise(_ exercise: SchemaV1.Exercise, to template: SchemaV1.WorkoutTemplate) async throws {}
    func removeExercise(_ templateExercise: SchemaV1.TemplateExercise, from template: SchemaV1.WorkoutTemplate) async throws {}
    func reorderExercises(_ template: SchemaV1.WorkoutTemplate, order: [UUID]) async throws {}
    func addSet(to templateExercise: SchemaV1.TemplateExercise) async throws -> SchemaV1.TemplateSet { fatalError() }
    func removeSet(_ set: SchemaV1.TemplateSet, from templateExercise: SchemaV1.TemplateExercise) async throws {}
    func updateSet(_ set: SchemaV1.TemplateSet, weight: Double?, reps: Int?, bodyweightModifier: Double?, time: TimeInterval?, distance: Double?, notes: String?) async throws {}
    func addExerciseWithSets(_ exercise: SchemaV1.Exercise, to template: SchemaV1.WorkoutTemplate, setCount: Int) async throws {}
    func updateExerciseNotes(_ templateExercise: SchemaV1.TemplateExercise, notes: String?) async throws {}
    func saveTemplate(existingId: PersistentIdentifier?, name: String, notes: String?, exercises: [DraftTemplateExercise]) async throws {}
}

#Preview("Empty State") {
    PreviewWorkoutPickerSheet()
}
