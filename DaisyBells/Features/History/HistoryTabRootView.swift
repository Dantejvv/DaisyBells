import SwiftUI
import SwiftData

@MainActor
struct HistoryTabRootView: View {
    @Environment(HistoryRouter.self) private var router

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router.path) {
            Text("History Content - Phase 5")
                .navigationTitle("History")
                .navigationDestination(for: HistoryRoute.self) { route in
                    // Route handling will be implemented in Phase 5
                    Text("Route: \(String(describing: route))")
                }
        }
        .sheet(item: $router.presentedSheet) { sheet in
            // Sheet presentation will be implemented in Phase 5
            Text("Sheet: \(sheet.id)")
        }
    }
}
