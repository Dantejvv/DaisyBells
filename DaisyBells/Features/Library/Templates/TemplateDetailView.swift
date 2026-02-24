import SwiftUI
import SwiftData

@MainActor
struct TemplateDetailView: View {
    @State var viewModel: TemplateDetailViewModel
    @State private var showDeleteConfirmation = false
    var onSheetDismissed: Bool = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingSpinnerView()
            } else if let template = viewModel.template {
                templateContent(template)
            }
        }
        .navigationTitle(viewModel.template?.name ?? "Template")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.editTemplate()
                } label: {
                    Text("Edit")
                }
            }
        }
        .task { await viewModel.loadTemplate() }
        .onChange(of: onSheetDismissed) {
            Task { await viewModel.loadTemplate() }
        }
        .errorAlert(errorMessage: $viewModel.errorMessage)
        .destructiveConfirmation(
            title: "Delete Template",
            message: "This template will be permanently deleted.",
            isPresented: $showDeleteConfirmation,
            onConfirm: {
                Task { await viewModel.deleteTemplate() }
            }
        )
        .background(Color.bgPrimary)
        .preferredColorScheme(.dark)
    }

    // MARK: - Content

    private func templateContent(_ template: SchemaV1.WorkoutTemplate) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                // Template info card
                if let notes = template.notes, !notes.isEmpty {
                    templateInfoCard(notes)
                }

                // Exercise cards
                if viewModel.exercises.isEmpty {
                    emptyExercises
                } else {
                    ForEach(viewModel.exercises, id: \.id) { templateExercise in
                        exerciseCard(templateExercise)
                    }
                }

                // Action buttons
                actionsCard
            }
            .padding(.horizontal, .spacingBase)
            .padding(.bottom, .spacing4xl)
        }
    }

    // MARK: - Template Info

    private func templateInfoCard(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: .spacingSm) {
            Text("Notes")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.textTertiary)
                .textCase(.uppercase)

            Text(notes)
                .font(.system(size: 13))
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: .radiusLg))
        .overlay(
            RoundedRectangle(cornerRadius: .radiusLg)
                .stroke(Color.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Empty State

    private var emptyExercises: some View {
        VStack(spacing: .spacingSm) {
            Text("No exercises added")
                .font(.system(size: 13))
                .foregroundStyle(Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .spacing2xl)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: .radiusLg))
        .overlay(
            RoundedRectangle(cornerRadius: .radiusLg)
                .stroke(Color.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Exercise Card

    private func exerciseCard(_ templateExercise: SchemaV1.TemplateExercise) -> some View {
        let exercise = templateExercise.exercise
        let exerciseType = exercise?.type ?? .weightAndReps
        let templateSets = templateExercise.sets.sorted { $0.order < $1.order }
        let previousSets = exercise.flatMap { viewModel.previousPerformance[$0.id] } ?? []
        let setCount = templateSets.isEmpty ? max(previousSets.count, 1) : templateSets.count

        return ExerciseCardContainer {
            ExerciseCardHeader(name: exercise?.name ?? "Unknown Exercise") {
                Text(exerciseType.displayName)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textTertiary)
            }

            // Exercise notes
            if let notes = templateExercise.notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.bottom, .spacingXs)
            }

            SetColumnHeaders(exerciseType: exerciseType)

            Rectangle()
                .fill(Color.borderSubtle)
                .frame(height: 1)

            ForEach(0..<setCount, id: \.self) { index in
                let templateSet = index < templateSets.count ? templateSets[index] : nil
                let previousSet = index < previousSets.count ? previousSets[index] : nil

                ReadOnlySetRow(
                    exerciseType: exerciseType,
                    setNumber: index + 1,
                    badgeStyle: .neutral,
                    weight: templateSet?.weight ?? previousSet?.weight,
                    reps: templateSet?.reps ?? previousSet?.reps,
                    bodyweightModifier: templateSet?.bodyweightModifier ?? previousSet?.bodyweightModifier,
                    time: templateSet?.time ?? previousSet?.time,
                    distance: templateSet?.distance ?? previousSet?.distance,
                    notes: templateSet != nil ? nil : previousSet?.notes
                )
            }

            Spacer()
                .frame(height: .spacingSm)
        }
    }

    // MARK: - Actions

    private var actionsCard: some View {
        VStack(spacing: 0) {
            if viewModel.canStartWorkout {
                actionButton(title: "Start Workout", color: .accent) {
                    Task { await viewModel.startWorkout() }
                }

                Rectangle()
                    .fill(Color.borderSubtle)
                    .frame(height: 1)
            }

            actionButton(title: "Duplicate Template", color: .accent) {
                Task { await viewModel.duplicateTemplate() }
            }

            Rectangle()
                .fill(Color.borderSubtle)
                .frame(height: 1)

            actionButton(title: "Delete Template", color: .destructive) {
                showDeleteConfirmation = true
            }
        }
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: .radiusLg))
        .overlay(
            RoundedRectangle(cornerRadius: .radiusLg)
                .stroke(Color.borderSubtle, lineWidth: 1)
        )
    }

    private func actionButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
    }
}

// MARK: - Preview

@MainActor
private func makePreviewContainer() -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let schema = Schema(SchemaV1.models)
    return try! ModelContainer(for: schema, configurations: config)
}

@MainActor
private func seedTemplatePreview(in ctx: ModelContext) -> PersistentIdentifier {
    let template = SchemaV1.WorkoutTemplate(name: "Push Day A")
    template.notes = "Focus on progressive overload"
    ctx.insert(template)

    let bench = SchemaV1.Exercise(name: "Bench Press", type: .weightAndReps)
    ctx.insert(bench)
    let te1 = SchemaV1.TemplateExercise(exercise: bench, order: 0)
    te1.template = template
    ctx.insert(te1)
    for i in 0..<3 {
        let ts = SchemaV1.TemplateSet(order: i)
        ts.weight = 135
        ts.reps = 10
        ts.templateExercise = te1
        ctx.insert(ts)
    }

    let ohp = SchemaV1.Exercise(name: "Overhead Press", type: .weightAndReps)
    ctx.insert(ohp)
    let te2 = SchemaV1.TemplateExercise(exercise: ohp, order: 1)
    te2.notes = "Strict form, no leg drive"
    te2.template = template
    ctx.insert(te2)
    for i in 0..<3 {
        let ts = SchemaV1.TemplateSet(order: i)
        ts.weight = 95
        ts.reps = 8
        ts.templateExercise = te2
        ctx.insert(ts)
    }

    let flyes = SchemaV1.Exercise(name: "Cable Flyes", type: .weightAndReps)
    ctx.insert(flyes)
    let te3 = SchemaV1.TemplateExercise(exercise: flyes, order: 2)
    te3.template = template
    ctx.insert(te3)

    try! ctx.save()
    return template.persistentModelID
}

@MainActor
private final class PreviewTemplateService: TemplateServiceProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() async throws -> [SchemaV1.WorkoutTemplate] { [] }
    func fetch(id: UUID) async throws -> SchemaV1.WorkoutTemplate { fatalError() }
    func fetch(by persistentId: PersistentIdentifier) -> SchemaV1.WorkoutTemplate? {
        modelContext.model(for: persistentId) as? SchemaV1.WorkoutTemplate
    }
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
    func updateSet(_ set: SchemaV1.TemplateSet, weight: Double?, reps: Int?, bodyweightModifier: Double?, time: TimeInterval?, distance: Double?) async throws {}
    func updateExerciseNotes(_ templateExercise: SchemaV1.TemplateExercise, notes: String?) async throws {}
}

@MainActor
private final class PreviewTemplateRouter: TemplateRouting {
    func navigateToTemplateDetail(templateId: PersistentIdentifier) {}
    func presentTemplateForm(templateId: PersistentIdentifier?) {}
    func dismissSheet() {}
    func pop() {}
}

#Preview("Template Detail") {
    let container = makePreviewContainer()
    let templateId = seedTemplatePreview(in: container.mainContext)

    NavigationStack {
        TemplateDetailView(
            viewModel: TemplateDetailViewModel(
                templateService: PreviewTemplateService(modelContext: container.mainContext),
                router: PreviewTemplateRouter(),
                templateId: templateId
            )
        )
    }
    .modelContainer(container)
}

@MainActor
private func seedEmptyTemplatePreview(in ctx: ModelContext) -> PersistentIdentifier {
    let template = SchemaV1.WorkoutTemplate(name: "Empty Template")
    ctx.insert(template)
    try! ctx.save()
    return template.persistentModelID
}

#Preview("Empty Template") {
    let container = makePreviewContainer()
    let templateId = seedEmptyTemplatePreview(in: container.mainContext)

    NavigationStack {
        TemplateDetailView(
            viewModel: TemplateDetailViewModel(
                templateService: PreviewTemplateService(modelContext: container.mainContext),
                router: PreviewTemplateRouter(),
                templateId: templateId
            )
        )
    }
    .modelContainer(container)
}
