import SwiftUI

@MainActor
struct LibraryRootView: View {
    @Environment(DependencyContainer.self) private var container
    @Environment(LibraryRouter.self) private var router

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Exercises")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button {
                    router.presentExerciseForm()
                } label: {
                    Image(systemName: "plus")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.accent)
                }
            }
            .padding(.horizontal, .spacingBase)
            .padding(.vertical, .spacingSm)

            ExerciseListView(
                viewModel: ExerciseListViewModel(
                    exerciseService: container.exerciseService,
                    categoryService: container.categoryService,
                    router: router
                )
            )
        }
        .background(Color.bgPrimary)
        .navigationBarTitleDisplayMode(.inline)
    }
}
