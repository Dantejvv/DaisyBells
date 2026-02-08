import SwiftUI

@MainActor
struct MainTabView: View {
    @Environment(DependencyContainer.self) private var container

    var body: some View {
        TabView {
            HomeTabRootView()
                .environment(container.homeRouter)
                .environment(container)
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            LibraryTabRootView()
                .environment(container.libraryRouter)
                .environment(container)
                .tabItem {
                    Label("Library", systemImage: "book")
                }

            HistoryTabRootView()
                .environment(container.historyRouter)
                .environment(container)
                .tabItem {
                    Label("History", systemImage: "clock")
                }

            AnalyticsTabRootView()
                .environment(container.analyticsRouter)
                .environment(container)
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar")
                }
        }
    }
}
