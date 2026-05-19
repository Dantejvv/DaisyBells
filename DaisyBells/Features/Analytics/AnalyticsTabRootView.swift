import SwiftUI
import SwiftData

@MainActor
struct AnalyticsTabRootView: View {
    @Environment(AnalyticsRouter.self) private var router
    @Environment(DependencyContainer.self) private var container

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router.path) {
            AnalyticsDashboardView(
                viewModel: AnalyticsDashboardViewModel(
                    analyticsService: container.analyticsService,
                    settingsService: container.settingsService,
                    router: router
                )
            )
            .navigationDestination(for: AnalyticsRoute.self) { route in
                switch route {
                case .exerciseAnalytics(let exerciseId):
                    ExerciseAnalyticsView(
                        viewModel: ExerciseAnalyticsViewModel(
                            analyticsService: container.analyticsService,
                            exerciseService: container.exerciseService,
                            settingsService: container.settingsService,
                            exerciseId: exerciseId
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
    }
}
