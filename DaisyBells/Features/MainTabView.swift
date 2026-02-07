import SwiftUI
import SwiftData

/// Main app shell with 4 tabs wired to NavigationStack routing
struct MainTabView: View {
    @Environment(DependencyContainer.self) private var container
    @State private var selectedTab: Tab = .library

    enum Tab: String, CaseIterable {
        case library = "Library"
        case routines = "Routines"
        case history = "History"
        case analytics = "Analytics"

        var systemImage: String {
            switch self {
            case .library: "books.vertical"
            case .routines: "figure.strengthtraining.traditional"
            case .history: "clock"
            case .analytics: "chart.bar"
            }
        }
    }

    var body: some View {
        @Bindable var libraryRouter = container.libraryRouter
        @Bindable var routinesRouter = container.routinesRouter
        @Bindable var historyRouter = container.historyRouter
        @Bindable var analyticsRouter = container.analyticsRouter

        TabView(selection: $selectedTab) {
            // MARK: - Library Tab
            NavigationStack(path: $libraryRouter.path) {
                LibraryRootView(container: container)
                    .navigationDestination(for: LibraryRoute.self) { route in
                        libraryDestination(for: route)
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                container.libraryRouter.presentSettings()
                            } label: {
                                Image(systemName: "gearshape")
                            }
                        }
                    }
            }
            .sheet(item: $libraryRouter.presentedSheet) { sheet in
                librarySheet(for: sheet)
            }
            .tabItem {
                Label(Tab.library.rawValue, systemImage: Tab.library.systemImage)
            }
            .tag(Tab.library)

            // MARK: - Routines Tab
            NavigationStack(path: $routinesRouter.path) {
                RoutinesRootView(container: container)
                    .navigationDestination(for: RoutinesRoute.self) { route in
                        routinesDestination(for: route)
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                container.routinesRouter.presentSettings()
                            } label: {
                                Image(systemName: "gearshape")
                            }
                        }
                    }
            }
            .sheet(item: $routinesRouter.presentedSheet) { sheet in
                routinesSheet(for: sheet)
            }
            .tabItem {
                Label(Tab.routines.rawValue, systemImage: Tab.routines.systemImage)
            }
            .tag(Tab.routines)

            // MARK: - History Tab
            NavigationStack(path: $historyRouter.path) {
                HistoryListView(
                    viewModel: HistoryListViewModel(
                        workoutService: container.workoutService,
                        router: container.historyRouter
                    )
                )
                .navigationDestination(for: HistoryRoute.self) { route in
                    historyDestination(for: route)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            container.historyRouter.presentSettings()
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
            }
            .sheet(item: $historyRouter.presentedSheet) { sheet in
                historySheet(for: sheet)
            }
            .tabItem {
                Label(Tab.history.rawValue, systemImage: Tab.history.systemImage)
            }
            .tag(Tab.history)

            // MARK: - Analytics Tab
            NavigationStack(path: $analyticsRouter.path) {
                AnalyticsDashboardView(
                    viewModel: AnalyticsDashboardViewModel(
                        analyticsService: container.analyticsService,
                        router: container.analyticsRouter
                    )
                )
                .navigationDestination(for: AnalyticsRoute.self) { route in
                    analyticsDestination(for: route)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            container.analyticsRouter.presentSettings()
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
            }
            .sheet(item: $analyticsRouter.presentedSheet) { sheet in
                analyticsSheet(for: sheet)
            }
            .tabItem {
                Label(Tab.analytics.rawValue, systemImage: Tab.analytics.systemImage)
            }
            .tag(Tab.analytics)
        }
    }

    // MARK: - Library Destinations

    @ViewBuilder
    private func libraryDestination(for route: LibraryRoute) -> some View {
        switch route {
        case .exerciseList(let categoryId):
            ExerciseListView(
                viewModel: ExerciseListViewModel(
                    exerciseService: container.exerciseService,
                    categoryService: container.categoryService,
                    router: container.libraryRouter,
                    categoryId: categoryId
                )
            )

        case .exerciseDetail(let exerciseId):
            ExerciseDetailView(
                viewModel: ExerciseDetailViewModel(
                    exerciseService: container.exerciseService,
                    router: container.libraryRouter,
                    exerciseId: exerciseId
                )
            )

        case .exerciseForm(let exerciseId):
            ExerciseFormView(
                viewModel: ExerciseFormViewModel(
                    exerciseService: container.exerciseService,
                    categoryService: container.categoryService,
                    router: container.libraryRouter,
                    exerciseId: exerciseId
                )
            )
        }
    }

    @ViewBuilder
    private func librarySheet(for sheet: LibrarySheet) -> some View {
        switch sheet {
        case .settings:
            NavigationStack {
                SettingsView(
                    viewModel: SettingsViewModel(
                        settingsService: container.settingsService
                    )
                )
            }
        }
    }

    // MARK: - Routines Destinations

    @ViewBuilder
    private func routinesDestination(for route: RoutinesRoute) -> some View {
        switch route {
        case .templateDetail(let templateId):
            TemplateDetailView(
                viewModel: TemplateDetailViewModel(
                    templateService: container.templateService,
                    workoutService: container.workoutService,
                    router: container.routinesRouter,
                    templateId: templateId
                )
            )

        case .templateForm(let templateId):
            TemplateFormView(
                viewModel: TemplateFormViewModel(
                    templateService: container.templateService,
                    exerciseService: container.exerciseService,
                    router: container.routinesRouter,
                    templateId: templateId
                )
            )

        case .activeWorkout(let workoutId):
            ActiveWorkoutView(
                viewModel: ActiveWorkoutViewModel(
                    workoutService: container.workoutService,
                    exerciseService: container.exerciseService,
                    templateService: container.templateService,
                    router: container.routinesRouter,
                    workoutId: workoutId
                )
            )
        }
    }

    @ViewBuilder
    private func routinesSheet(for sheet: RoutinesSheet) -> some View {
        switch sheet {
        case .exercisePicker:
            NavigationStack {
                ExercisePickerView(
                    viewModel: ExercisePickerViewModel(
                        exerciseService: container.exerciseService,
                        categoryService: container.categoryService,
                        onSelect: { exerciseId in
                            container.routinesRouter.onExerciseSelected?(exerciseId)
                        }
                    )
                )
            }

        case .settings:
            NavigationStack {
                SettingsView(
                    viewModel: SettingsViewModel(
                        settingsService: container.settingsService
                    )
                )
            }
        }
    }

    // MARK: - History Destinations

    @ViewBuilder
    private func historyDestination(for route: HistoryRoute) -> some View {
        switch route {
        case .workoutDetail(let workoutId):
            CompletedWorkoutDetailView(
                viewModel: CompletedWorkoutDetailViewModel(
                    workoutService: container.workoutService,
                    router: container.historyRouter,
                    workoutId: workoutId
                )
            )
        }
    }

    @ViewBuilder
    private func historySheet(for sheet: HistorySheet) -> some View {
        switch sheet {
        case .settings:
            NavigationStack {
                SettingsView(
                    viewModel: SettingsViewModel(
                        settingsService: container.settingsService
                    )
                )
            }
        }
    }

    // MARK: - Analytics Destinations

    @ViewBuilder
    private func analyticsDestination(for route: AnalyticsRoute) -> some View {
        switch route {
        case .exerciseAnalytics(let exerciseId):
            ExerciseAnalyticsView(
                viewModel: ExerciseAnalyticsViewModel(
                    analyticsService: container.analyticsService,
                    exerciseService: container.exerciseService,
                    exerciseId: exerciseId
                )
            )
        }
    }

    @ViewBuilder
    private func analyticsSheet(for sheet: AnalyticsSheet) -> some View {
        switch sheet {
        case .settings:
            NavigationStack {
                SettingsView(
                    viewModel: SettingsViewModel(
                        settingsService: container.settingsService
                    )
                )
            }
        }
    }
}

// MARK: - Library Root View

/// The root view for the Library tab showing exercise categories only
private struct LibraryRootView: View {
    let container: DependencyContainer
    @State private var viewModel: CategoryListViewModel

    init(container: DependencyContainer) {
        self.container = container
        _viewModel = State(initialValue: CategoryListViewModel(
            categoryService: container.categoryService,
            router: container.libraryRouter
        ))
    }

    var body: some View {
        List {
            if viewModel.categories.isEmpty && !viewModel.isLoading {
                Text("No categories")
                    .foregroundStyle(.secondary)
                    .italic()
            } else {
                ForEach(viewModel.categories) { category in
                    Button {
                        viewModel.selectCategory(category)
                    } label: {
                        HStack {
                            Text(category.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("\(category.exercises.count)")
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Library")
        .task { await viewModel.loadCategories() }
    }
}

// MARK: - Routines Root View

/// The root view for the Routines tab showing templates and start workout options
private struct RoutinesRootView: View {
    let container: DependencyContainer
    @State private var viewModel: TemplateListViewModel
    @State private var deleteConfig: ConfirmationDialogConfig?

    init(container: DependencyContainer) {
        self.container = container
        _viewModel = State(initialValue: TemplateListViewModel(
            templateService: container.templateService,
            router: container.routinesRouter
        ))
    }

    var body: some View {
        List {
            Section {
                Button {
                    Task { await startBlankWorkout() }
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                        Text("Start Blank Workout")
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Templates") {
                if viewModel.templates.isEmpty && !viewModel.isLoading {
                    Text("No templates yet")
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
                    ForEach(viewModel.templates) { template in
                        Button {
                            viewModel.selectTemplate(template)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(template.name)
                                        .foregroundStyle(.primary)
                                    Text("\(template.templateExercises.count) exercises")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Delete", role: .destructive) {
                                deleteConfig = ConfirmationDialogConfig(
                                    title: "Delete \"\(template.name)\"?",
                                    message: "This template will be permanently deleted. Your workout history will not be affected.",
                                    confirmTitle: "Delete"
                                ) {
                                    Task { await viewModel.deleteTemplate(template) }
                                }
                            }
                        }
                    }
                }

                Button {
                    viewModel.createTemplate()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Template")
                    }
                }
            }
        }
        .navigationTitle("Routines")
        .confirmationDialog($deleteConfig)
        .errorAlert(Binding(
            get: { viewModel.errorMessage },
            set: { viewModel.errorMessage = $0 }
        ))
        .task { await viewModel.loadTemplates() }
    }

    private func startBlankWorkout() async {
        do {
            let workout = try await container.workoutService.createEmpty()
            container.routinesRouter.navigateToActiveWorkout(workoutId: workout.persistentModelID)
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }
}
