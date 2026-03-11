import SwiftUI
import SwiftData

@MainActor
struct LibraryTabRootView: View {
    @Environment(LibraryRouter.self) private var router
    @Environment(DependencyContainer.self) private var container

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router.path) {
            LibraryRootView()
                .navigationDestination(for: LibraryRoute.self) { route in
                    switch route {
                    case .exerciseList(let categoryId):
                        ExerciseListView(
                            viewModel: ExerciseListViewModel(
                                exerciseService: container.exerciseService,
                                categoryService: container.categoryService,
                                router: router,
                                categoryId: categoryId
                            )
                        )
                    case .exerciseDetail(let exerciseId):
                        ExerciseDetailView(
                            viewModel: ExerciseDetailViewModel(
                                exerciseService: container.exerciseService,
                                analyticsService: container.analyticsService,
                                settingsService: container.settingsService,
                                router: router,
                                exerciseId: exerciseId
                            )
                        )
                    case .templateDetail(let templateId):
                        TemplateDetailView(
                            viewModel: TemplateDetailViewModel(
                                templateService: container.templateService,
                                workoutService: container.workoutService,
                                settingsService: container.settingsService,
                                router: router,
                                templateId: templateId
                            ),
                            onSheetDismissed: router.presentedSheet == nil
                        )
                    }
                }
        }
        .sheet(item: $router.presentedSheet) { sheet in
            switch sheet {
            case .exerciseForm(let exerciseId):
                NavigationStack {
                    ExerciseFormView(
                        viewModel: ExerciseFormViewModel(
                            exerciseService: container.exerciseService,
                            categoryService: container.categoryService,
                            router: router,
                            exerciseId: exerciseId
                        )
                    )
                }
            case .exercisePicker:
                NavigationStack {
                    ExercisePickerSheet(
                        viewModel: ExercisePickerViewModel(
                            exerciseService: container.exerciseService,
                            categoryService: container.categoryService,
                            onSelect: { exerciseIds in
                                router.onExerciseSelected?(exerciseIds)
                            }
                        )
                    )
                }
            case .templateForm(let templateId):
                NavigationStack {
                    TemplateFormView(
                        viewModel: TemplateFormViewModel(
                            templateService: container.templateService,
                            exerciseService: container.exerciseService,
                            workoutService: container.workoutService,
                            router: router,
                            templateId: templateId
                        )
                    )
                }
            }
        }
    }
}
