import SwiftUI

@MainActor
struct LibraryRootView: View {
    @Environment(DependencyContainer.self) private var container
    @Environment(LibraryRouter.self) private var router

    var body: some View {
        ExerciseListView(
            viewModel: ExerciseListViewModel(
                exerciseService: container.exerciseService,
                categoryService: container.categoryService,
                router: router
            )
        )
        .background(Color.bgPrimary)
    }
}
