import Testing
import Foundation
@testable import DaisyBells

@Suite(.serialized)
struct KeyboardFocusCoordinatorTests {

    private func makeInput(setNumber: Int, setID: AnyHashable, type: ExerciseType = .weightAndReps) -> SetFocusInput {
        SetFocusInput(
            exerciseName: "Bench Press",
            exerciseType: type,
            setNumber: setNumber,
            setID: setID
        )
    }

    // MARK: - Empty list

    @Test @MainActor
    func emptyListHasNoNextOrPrevious() {
        let coordinator = KeyboardFocusCoordinator()

        #expect(coordinator.next(of: nil) == nil)
        #expect(coordinator.previous(of: nil) == nil)
        #expect(coordinator.hasNext(of: nil) == false)
        #expect(coordinator.hasPrevious(of: nil) == false)
    }

    @Test @MainActor
    func emptyListRejectsStaleField() {
        let coordinator = KeyboardFocusCoordinator()
        let stale = FocusedSetField.weight(AnyHashable(UUID()))

        #expect(coordinator.next(of: stale) == nil)
        #expect(coordinator.previous(of: stale) == nil)
    }

    // MARK: - Single set, weightAndReps

    @Test @MainActor
    func singleSetWeightAndRepsHasTwoFields() {
        let coordinator = KeyboardFocusCoordinator()
        let id = AnyHashable(UUID())
        coordinator.update(from: [makeInput(setNumber: 1, setID: id)])

        #expect(coordinator.orderedFields.count == 2)
        #expect(coordinator.orderedFields[0] == .weight(id))
        #expect(coordinator.orderedFields[1] == .reps(id))
    }

    @Test @MainActor
    func nextAndPreviousWithinSingleSet() {
        let coordinator = KeyboardFocusCoordinator()
        let id = AnyHashable(UUID())
        coordinator.update(from: [makeInput(setNumber: 1, setID: id)])

        #expect(coordinator.next(of: .weight(id)) == .reps(id))
        #expect(coordinator.previous(of: .reps(id)) == .weight(id))
        #expect(coordinator.next(of: .reps(id)) == nil)
        #expect(coordinator.previous(of: .weight(id)) == nil)
    }

    @Test @MainActor
    func hasNextHasPreviousFlagsForSingleSet() {
        let coordinator = KeyboardFocusCoordinator()
        let id = AnyHashable(UUID())
        coordinator.update(from: [makeInput(setNumber: 1, setID: id)])

        #expect(coordinator.hasNext(of: .weight(id)) == true)
        #expect(coordinator.hasNext(of: .reps(id)) == false)
        #expect(coordinator.hasPrevious(of: .weight(id)) == false)
        #expect(coordinator.hasPrevious(of: .reps(id)) == true)
    }

    // MARK: - Multi-set traversal

    @Test @MainActor
    func traversalAcrossThreeSets() {
        let coordinator = KeyboardFocusCoordinator()
        let id1 = AnyHashable(UUID())
        let id2 = AnyHashable(UUID())
        let id3 = AnyHashable(UUID())
        coordinator.update(from: [
            makeInput(setNumber: 1, setID: id1),
            makeInput(setNumber: 2, setID: id2),
            makeInput(setNumber: 3, setID: id3)
        ])

        #expect(coordinator.orderedFields.count == 6)

        // Forward walk: weight1 → reps1 → weight2 → reps2 → weight3 → reps3
        #expect(coordinator.next(of: .weight(id1)) == .reps(id1))
        #expect(coordinator.next(of: .reps(id1)) == .weight(id2))
        #expect(coordinator.next(of: .weight(id2)) == .reps(id2))
        #expect(coordinator.next(of: .reps(id2)) == .weight(id3))
        #expect(coordinator.next(of: .weight(id3)) == .reps(id3))
        #expect(coordinator.next(of: .reps(id3)) == nil)

        // Backward walk
        #expect(coordinator.previous(of: .reps(id3)) == .weight(id3))
        #expect(coordinator.previous(of: .weight(id3)) == .reps(id2))
        #expect(coordinator.previous(of: .reps(id2)) == .weight(id2))
        #expect(coordinator.previous(of: .weight(id2)) == .reps(id1))
        #expect(coordinator.previous(of: .reps(id1)) == .weight(id1))
        #expect(coordinator.previous(of: .weight(id1)) == nil)
    }

    // MARK: - Exercise type variants

    @Test @MainActor
    func bodyweightAndRepsExposesModifierThenReps() {
        let coordinator = KeyboardFocusCoordinator()
        let id = AnyHashable(UUID())
        coordinator.update(from: [
            makeInput(setNumber: 1, setID: id, type: .bodyweightAndReps)
        ])

        #expect(coordinator.orderedFields == [.bodyweightModifier(id), .reps(id)])
    }

    @Test @MainActor
    func distanceAndTimeExposesDistanceThenTime() {
        let coordinator = KeyboardFocusCoordinator()
        let id = AnyHashable(UUID())
        coordinator.update(from: [
            makeInput(setNumber: 1, setID: id, type: .distanceAndTime)
        ])

        #expect(coordinator.orderedFields == [.distance(id), .time(id)])
    }

    @Test @MainActor
    func repsOnlyExposesSingleField() {
        let coordinator = KeyboardFocusCoordinator()
        let id = AnyHashable(UUID())
        coordinator.update(from: [
            makeInput(setNumber: 1, setID: id, type: .reps)
        ])

        #expect(coordinator.orderedFields == [.reps(id)])
        #expect(coordinator.hasNext(of: .reps(id)) == false)
        #expect(coordinator.hasPrevious(of: .reps(id)) == false)
    }

    // MARK: - Stale field handling

    @Test @MainActor
    func nextReturnsNilForFieldNotInList() {
        let coordinator = KeyboardFocusCoordinator()
        let id = AnyHashable(UUID())
        let stale = AnyHashable(UUID())
        coordinator.update(from: [makeInput(setNumber: 1, setID: id)])

        #expect(coordinator.next(of: .weight(stale)) == nil)
        #expect(coordinator.previous(of: .reps(stale)) == nil)
        #expect(coordinator.hasNext(of: .weight(stale)) == false)
        #expect(coordinator.hasPrevious(of: .weight(stale)) == false)
    }

    @Test @MainActor
    func updateInvalidatesPreviouslyValidFields() {
        let coordinator = KeyboardFocusCoordinator()
        let oldID = AnyHashable(UUID())
        let newID = AnyHashable(UUID())

        coordinator.update(from: [makeInput(setNumber: 1, setID: oldID)])
        #expect(coordinator.next(of: .weight(oldID)) == .reps(oldID))

        // Simulate set deletion: rebuild list without the old ID.
        coordinator.update(from: [makeInput(setNumber: 1, setID: newID)])

        #expect(coordinator.next(of: .weight(oldID)) == nil)
        #expect(coordinator.hasNext(of: .weight(oldID)) == false)
    }

    // MARK: - Labels

    @Test @MainActor
    func labelsIncludeSetNumberAndFieldName() {
        let coordinator = KeyboardFocusCoordinator()
        let id = AnyHashable(UUID())
        coordinator.update(from: [makeInput(setNumber: 2, setID: id)])

        #expect(coordinator.label(for: .weight(id)) == "Set 2 · Weight")
        #expect(coordinator.label(for: .reps(id)) == "Set 2 · Reps")
    }

    @Test @MainActor
    func labelReturnsNilForUnknownField() {
        let coordinator = KeyboardFocusCoordinator()
        #expect(coordinator.label(for: nil) == nil)
        #expect(coordinator.label(for: .weight(AnyHashable(UUID()))) == nil)
    }
}
