import SwiftUI
import SwiftData

@MainActor
struct HomeTabRootView: View {
    @Environment(HomeRouter.self) private var router
    @Environment(DependencyContainer.self) private var container

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router.path) {
            HomeDashboardView(
                viewModel: HomeDashboardViewModel(
                    templateService: container.templateService,
                    splitService: container.splitService,
                    workoutService: container.workoutService,
                    settingsService: container.settingsService,
                    activeWorkoutManager: container.activeWorkoutManager,
                    router: router
                )
            )
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .templateDetail(let templateId):
                    TemplateDetailView(
                        viewModel: TemplateDetailViewModel(
                            templateService: container.templateService,
                            workoutService: container.workoutService,
                            splitDayService: container.splitDayService,
                            settingsService: container.settingsService,
                            activeWorkoutManager: container.activeWorkoutManager,
                            router: router,
                            templateId: templateId
                        ),
                        onSheetDismissed: router.presentedSheet == nil
                    )
                case .splitList:
                    SplitListView(
                        viewModel: SplitListViewModel(
                            splitService: container.splitService,
                            settingsService: container.settingsService,
                            router: router
                        )
                    )
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if container.activeWorkoutManager.hasActiveWorkout && !container.activeWorkoutManager.isShowingSheet {
                    ActiveWorkoutFloatingButton()
                        .environment(container.activeWorkoutManager)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.snappy(duration: 0.3), value: container.activeWorkoutManager.hasActiveWorkout)
            .animation(.snappy(duration: 0.3), value: container.activeWorkoutManager.isShowingSheet)
        }
        .sheet(item: $router.presentedSheet) { sheet in
            switch sheet {
            case .templateForm(let templateId):
                NavigationStack {
                    TemplateFormView(
                        viewModel: TemplateFormViewModel(
                            templateService: container.templateService,
                            exerciseService: container.exerciseService,
                            workoutService: container.workoutService,
                            router: router,
                            templateId: templateId
                        )
                    )
                }
            case .splitForm(let splitId):
                NavigationStack {
                    SplitFormView(
                        viewModel: SplitFormViewModel(
                            splitService: container.splitService,
                            splitDayService: container.splitDayService,
                            templateService: container.templateService,
                            splitId: splitId
                        )
                    )
                }
            case .exercisePicker:
                EmptyView()
            case .workoutPicker:
                NavigationStack {
                    WorkoutPickerSheet(
                        viewModel: WorkoutPickerViewModel(
                            templateService: container.templateService,
                            onSelect: { templateId in
                                router.onWorkoutSelected?(templateId)
                            }
                        )
                    )
                }
            }
        }
    }
}
