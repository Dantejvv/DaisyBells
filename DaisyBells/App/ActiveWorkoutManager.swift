import Foundation
import SwiftData

@MainActor @Observable
final class ActiveWorkoutManager {
    // MARK: - State

    private(set) var activeWorkoutId: PersistentIdentifier?
    private(set) var workoutName: String?
    private(set) var startedAt: Date?
    private(set) var elapsedTime: TimeInterval = 0
    var isShowingSheet = false

    // Split context — set when workout is started from split dashboard
    var activeSplitDayIndex: Int?
    var onWorkoutCompleted: (() async -> Void)?

    var hasActiveWorkout: Bool { activeWorkoutId != nil }

    // MARK: - Dependencies

    private let workoutService: WorkoutServiceProtocol
    private var timerTask: Task<Void, Never>? {
        willSet { timerTask?.cancel() }
    }

    // MARK: - Init

    init(workoutService: WorkoutServiceProtocol) {
        self.workoutService = workoutService
    }

    // MARK: - Public Methods

    func checkForActiveWorkout() async {
        do {
            if let workout = try await workoutService.fetchActive() {
                activeWorkoutId = workout.persistentModelID
                workoutName = workout.fromTemplate?.name
                startedAt = workout.startedAt
                startTimer()
            }
        } catch {
            // Silently fail — no active workout to recover
        }
    }

    func start(workoutId: PersistentIdentifier, name: String?, startedAt: Date, splitDayIndex: Int? = nil) {
        activeWorkoutId = workoutId
        workoutName = name
        self.startedAt = startedAt
        self.activeSplitDayIndex = splitDayIndex
        startTimer()
        isShowingSheet = true
    }

    func showSheet() {
        guard hasActiveWorkout else { return }
        isShowingSheet = true
    }

    func dismissSheet() {
        isShowingSheet = false
    }

    func updateStartedAt(_ date: Date) {
        startedAt = date
        startTimer()
    }

    func clearWorkout() {
        stopTimer()
        activeWorkoutId = nil
        workoutName = nil
        startedAt = nil
        elapsedTime = 0
        isShowingSheet = false
        activeSplitDayIndex = nil
        onWorkoutCompleted = nil
    }

    // MARK: - Private

    private func startTimer() {
        guard let startedAt else { return }

        elapsedTime = Date().timeIntervalSince(startedAt)

        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self, let startedAt = self.startedAt else { return }
                self.elapsedTime = Date().timeIntervalSince(startedAt)
            }
        }
    }

    private func stopTimer() {
        timerTask = nil
    }
}
