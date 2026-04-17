import SwiftUI

@MainActor
struct ProfileTabRootView: View {
    @Environment(DependencyContainer.self) private var container

    var body: some View {
        ProfileView(
            viewModel: SettingsViewModel(
                settingsService: container.settingsService,
                dataService: container.dataService,
                onAppearanceChanged: { [weak container] appearance in
                    container?.updateAppearance(appearance)
                }
            )
        )
    }
}
