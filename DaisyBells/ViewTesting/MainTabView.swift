import SwiftUI

/// Main app shell with 3 tabs (Library, History, Analytics) and settings button
struct MainTabView: View {
    @State private var selectedTab: Tab = .library
    @State private var showSettings = false

    enum Tab: String, CaseIterable {
        case library = "Library"
        case history = "History"
        case analytics = "Analytics"

        var systemImage: String {
            switch self {
            case .library: "books.vertical"
            case .history: "clock"
            case .analytics: "chart.bar"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(Tab.allCases, id: \.self) { tab in
                NavigationStack {
                    tabContent(for: tab)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button {
                                    showSettings = true
                                } label: {
                                    Image(systemName: "gearshape")
                                }
                            }
                        }
                }
                .tabItem {
                    Label(tab.rawValue, systemImage: tab.systemImage)
                }
                .tag(tab)
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsPlaceholderView()
            }
        }
    }

    @ViewBuilder
    private func tabContent(for tab: Tab) -> some View {
        switch tab {
        case .library:
            LibraryPlaceholderView()
                .navigationTitle("Library")
        case .history:
            HistoryPlaceholderView()
                .navigationTitle("History")
        case .analytics:
            AnalyticsPlaceholderView()
                .navigationTitle("Analytics")
        }
    }
}

// MARK: - Placeholder Views for Tab Content

private struct LibraryPlaceholderView: View {
    var body: some View {
        List {
            Section("Categories") {
                NavigationLink("Upper Body") { Text("Category detail") }
                NavigationLink("Lower Body") { Text("Category detail") }
                NavigationLink("Core") { Text("Category detail") }
            }

            Section("Templates") {
                NavigationLink("Push Day") { Text("Template detail") }
                NavigationLink("Pull Day") { Text("Template detail") }
                NavigationLink("Leg Day") { Text("Template detail") }
            }
        }
    }
}

private struct HistoryPlaceholderView: View {
    var body: some View {
        List {
            Section("This Week") {
                Text("Push Day - Today")
                Text("Pull Day - Yesterday")
            }
            Section("Last Week") {
                Text("Leg Day - 5 days ago")
                Text("Push Day - 6 days ago")
            }
        }
    }
}

private struct AnalyticsPlaceholderView: View {
    var body: some View {
        List {
            Section("Summary") {
                HStack {
                    Text("Workouts This Week")
                    Spacer()
                    Text("3")
                        .fontWeight(.semibold)
                }
                HStack {
                    Text("Workouts This Month")
                    Spacer()
                    Text("12")
                        .fontWeight(.semibold)
                }
            }
            Section("Recent PRs") {
                Text("Bench Press - 225 lbs")
                Text("Squat - 315 lbs")
            }
        }
    }
}

private struct SettingsPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section("Preferences") {
                Text("Units: lbs")
                Text("Appearance: System")
            }
            Section("Data") {
                Text("Export Data")
                Text("Import Data")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    MainTabView()
}
