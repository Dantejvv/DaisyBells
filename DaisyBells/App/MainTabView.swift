import SwiftUI

@MainActor
struct MainTabView: View {
    @Environment(DependencyContainer.self) private var container

    var body: some View {
        @Bindable var manager = container.activeWorkoutManager

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

            ProfileTabRootView()
                .environment(container)
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
        .sheet(isPresented: $manager.isShowingSheet) {
            ActiveWorkoutSheet()
                .environment(container)
                .environment(container.activeWorkoutManager)
                .interactiveDismissDisabled(false)
        }
        .animation(.snappy(duration: 0.3), value: manager.isShowingSheet)
    }
}
