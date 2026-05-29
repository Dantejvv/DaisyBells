import SwiftUI
import SwiftData

@MainActor
struct HistoryTabRootView: View {
    @Environment(HistoryRouter.self) private var router
    @Environment(DependencyContainer.self) private var container

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router.path) {
            HistoryListView(
                viewModel: HistoryListViewModel(
                    workoutService: container.workoutService,
                    settingsService: container.settingsService,
                    router: router
                )
            )
            .navigationDestination(for: HistoryRoute.self) { route in
                switch route {
                case .workoutDetail(let workoutId):
                    CompletedWorkoutDetailView(
                        viewModel: CompletedWorkoutDetailViewModel(
                            workoutService: container.workoutService,
                            templateService: container.templateService,
                            settingsService: container.settingsService,
                            router: router,
                            workoutId: workoutId
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
            Group {
                switch sheet {
                case .calendar:
                    HistoryCalendarSheet(
                        viewModel: HistoryCalendarViewModel(
                            workoutService: container.workoutService
                        )
                    )
                }
            }
            .presentationBackground(Color.bgPrimary)
        }
    }
}
