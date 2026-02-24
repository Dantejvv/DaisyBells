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
                            settingsService: container.settingsService,
                            router: router,
                            workoutId: workoutId
                        )
                    )
                }
            }
        }
    }
}
