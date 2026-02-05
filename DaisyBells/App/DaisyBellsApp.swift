import SwiftUI
import SwiftData

@main
struct DaisyBellsApp: App {
    @State private var dependencyContainer: DependencyContainer

    init() {
        do {
            _dependencyContainer = State(initialValue: try DependencyContainer())
        } catch {
            fatalError("Failed to create DependencyContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .task {
                    await dependencyContainer.performSetup()
                }
        }
        .modelContainer(dependencyContainer.modelContainer)
        .environment(dependencyContainer)
    }
}
