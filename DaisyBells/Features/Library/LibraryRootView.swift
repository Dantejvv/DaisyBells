import SwiftUI

@MainActor
struct LibraryRootView: View {
    @Environment(DependencyContainer.self) private var container
    @Environment(LibraryRouter.self) private var router
    @State private var selectedSegment = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: .spacingSm) {
                Picker("Library", selection: $selectedSegment) {
                    Text("Workouts").tag(0)
                    Text("Exercises").tag(1)
                }
                .pickerStyle(.segmented)

                Button {
                    if selectedSegment == 0 {
                        router.presentTemplateForm()
                    } else {
                        router.presentExerciseForm()
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.accent)
                }
            }
            .padding(.horizontal, .spacingBase)
            .padding(.vertical, .spacingSm)

            if selectedSegment == 0 {
                TemplateListView(
                    viewModel: TemplateListViewModel(
                        templateService: container.templateService,
                        router: router
                    )
                )
            } else {
                ExerciseListView(
                    viewModel: ExerciseListViewModel(
                        exerciseService: container.exerciseService,
                        categoryService: container.categoryService,
                        router: router
                    )
                )
            }
        }
        .background(Color.bgPrimary)
        .navigationBarTitleDisplayMode(.inline)
    }
}
