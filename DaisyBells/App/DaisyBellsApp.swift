import SwiftUI
import SwiftData
import UIKit

@main
struct DaisyBellsApp: App {
    @State private var dependencyContainer: DependencyContainer

    init() {
        Self.configureKeyboardToolbarAppearance()
        do {
            _dependencyContainer = State(initialValue: try DependencyContainer())
        } catch {
            fatalError("Failed to create DependencyContainer: \(error)")
        }
    }

    private static func configureKeyboardToolbarAppearance() {
        // SwiftUI's .toolbar(placement: .keyboard) is backed by a UIToolbar in a
        // UIInputAccessoryView. The default tint shows as a grey strip above the
        // keyboard (visible without a hardware keyboard hidden). Match the app bg.
        let appearance = UIToolbarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.bgPrimary)
        appearance.shadowColor = .clear
        UIToolbar.appearance().standardAppearance = appearance
        UIToolbar.appearance().compactAppearance = appearance
        UIToolbar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(dependencyContainer.currentAppearance.colorScheme)
                .task {
                    await dependencyContainer.performSetup()
                }
        }
        .modelContainer(dependencyContainer.modelContainer)
        .environment(dependencyContainer)
    }
}
