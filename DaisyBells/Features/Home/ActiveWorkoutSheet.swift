import SwiftUI
import SwiftData

@MainActor
struct ActiveWorkoutSheet: View {
    @Environment(DependencyContainer.self) private var container
    @Environment(ActiveWorkoutManager.self) private var manager

    @State private var showingExercisePicker = false
    @State private var exercisePickerCallback: (([PersistentIdentifier]) -> Void)?

    var body: some View {
        NavigationStack {
            if let workoutId = manager.activeWorkoutId {
                ActiveWorkoutView(
                    viewModel: makeViewModel(workoutId: workoutId)
                )
            }
        }
        .sheet(isPresented: $showingExercisePicker) {
            NavigationStack {
                ExercisePickerSheet(
                    viewModel: ExercisePickerViewModel(
                        exerciseService: container.exerciseService,
                        categoryService: container.categoryService,
                        onSelect: { exerciseIds in
                            exercisePickerCallback?(exerciseIds)
                        }
                    )
                )
            }
        }
    }

    private func makeViewModel(workoutId: PersistentIdentifier) -> ActiveWorkoutViewModel {
        let vm = ActiveWorkoutViewModel(
            workoutService: container.workoutService,
            exerciseService: container.exerciseService,
            loggedExerciseService: container.loggedExerciseService,
            loggedSetService: container.loggedSetService,
            templateService: container.templateService,
            settingsService: container.settingsService,
            workoutId: workoutId
        )
        vm.onDismiss = {
            manager.clearWorkout()
        }
        vm.onComplete = {
            await manager.onWorkoutCompleted?()
            manager.clearWorkout()
        }
        vm.onPresentExercisePicker = { callback in
            exercisePickerCallback = callback
            showingExercisePicker = true
        }
        vm.onTimerReset = { newDate in
            manager.updateStartedAt(newDate)
        }
        vm.onDismissExercisePicker = {
            showingExercisePicker = false
            exercisePickerCallback = nil
        }
        return vm
    }
}
