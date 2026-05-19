import SwiftUI

@MainActor
struct ProfileTabRootView: View {
    @Environment(DependencyContainer.self) private var container

    var body: some View {
        NavigationStack {
            ProfileView(
                viewModel: SettingsViewModel(
                    settingsService: container.settingsService,
                    dataService: container.dataService,
                    onAppearanceChanged: { [weak container] appearance in
                        container?.updateAppearance(appearance)
                    }
                )
            )
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
