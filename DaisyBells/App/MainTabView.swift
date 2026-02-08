import SwiftUI

/// Temporary stub view for data layer refactoring
/// Will be replaced with full implementation in Phase 7+
struct MainTabView: View {
    var body: some View {
        TabView {
            Text("Home")
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            Text("Library")
                .tabItem {
                    Label("Library", systemImage: "book")
                }

            Text("History")
                .tabItem {
                    Label("History", systemImage: "clock")
                }

            Text("Analytics")
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar")
                }
        }
    }
}
