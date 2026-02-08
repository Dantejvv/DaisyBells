import Foundation
import SwiftData

@MainActor @Observable
final class SplitDayDetailViewModel {
    // MARK: - State

    private(set) var day: SchemaV1.SplitDay?
    private(set) var assignedWorkouts: [SchemaV1.WorkoutTemplate] = []
    private(set) var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let splitDayService: SplitDayServiceProtocol
    private let workoutService: WorkoutServiceProtocol
    private let templateService: TemplateServiceProtocol
    private let router: HomeRouter
    private let dayId: PersistentIdentifier

    // MARK: - Init

    init(
        splitDayService: SplitDayServiceProtocol,
        workoutService: WorkoutServiceProtocol,
        templateService: TemplateServiceProtocol,
        router: HomeRouter,
        dayId: PersistentIdentifier
    ) {
        self.splitDayService = splitDayService
        self.workoutService = workoutService
        self.templateService = templateService
        self.router = router
        self.dayId = dayId
    }

    // MARK: - Intents

    func loadDay() async {
        isLoading = true
        errorMessage = nil

        guard let dayModel = splitDayService.fetch(by: dayId) else {
            errorMessage = "Split day not found"
            isLoading = false
            return
        }

        day = dayModel
        assignedWorkouts = dayModel.assignedWorkouts.sorted { $0.name < $1.name }
        isLoading = false
    }

    func editDay() {
        guard let day, let split = day.split else { return }
        router.navigateToEditDay(splitId: split.persistentModelID, dayId: dayId)
    }

    func deleteDay() async {
        guard let day, let split = day.split else { return }
        errorMessage = nil
        do {
            try await splitDayService.delete(day, from: split)
            router.pop()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func assignWorkout() {
        router.presentWorkoutPicker { [weak self] templateId in
            guard let self else { return }
            Task {
                await self.handleWorkoutSelection(templateId)
            }
        }
    }

    func unassignWorkout(_ workout: SchemaV1.WorkoutTemplate) async {
        guard let day else { return }
        errorMessage = nil
        do {
            try await splitDayService.unassignWorkout(workout, from: day)
            await loadDay()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startWorkout(_ workout: SchemaV1.WorkoutTemplate) async {
        errorMessage = nil
        do {
            let workoutInstance = try await workoutService.createFromTemplate(workout)
            router.navigateToActiveWorkout(workoutId: workoutInstance.persistentModelID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Private

    private func handleWorkoutSelection(_ templateId: PersistentIdentifier) async {
        guard let day else { return }

        guard let template = templateService.fetch(by: templateId) else {
            errorMessage = "Workout template not found"
            router.dismissSheet()
            return
        }

        errorMessage = nil

        do {
            try await splitDayService.assignWorkout(template, to: day)
            await loadDay()
            router.dismissSheet()
        } catch {
            errorMessage = error.localizedDescription
            router.dismissSheet()
        }
    }
}
