import SwiftUI

struct SetFocusInput {
    let exerciseName: String
    let exerciseType: ExerciseType
    let setNumber: Int
    let setID: AnyHashable
}

@MainActor
@Observable
final class KeyboardFocusCoordinator {
    private(set) var orderedFields: [FocusedSetField] = []
    private(set) var labels: [FocusedSetField: String] = [:]

    func update(from inputs: [SetFocusInput]) {
        var fields: [FocusedSetField] = []
        var labels: [FocusedSetField: String] = [:]

        for input in inputs {
            let setFields = Self.fields(for: input.exerciseType, setID: input.setID)
            for field in setFields {
                fields.append(field)
                labels[field] = Self.label(for: field, input: input)
            }
        }

        self.orderedFields = fields
        self.labels = labels
    }

    func index(of field: FocusedSetField?) -> Int? {
        guard let field else { return nil }
        return orderedFields.firstIndex(of: field)
    }

    func previous(of current: FocusedSetField?) -> FocusedSetField? {
        guard let i = index(of: current), i > 0 else { return nil }
        return orderedFields[i - 1]
    }

    func next(of current: FocusedSetField?) -> FocusedSetField? {
        guard let i = index(of: current), i < orderedFields.count - 1 else { return nil }
        return orderedFields[i + 1]
    }

    func hasPrevious(of current: FocusedSetField?) -> Bool {
        guard let i = index(of: current) else { return false }
        return i > 0
    }

    func hasNext(of current: FocusedSetField?) -> Bool {
        guard let i = index(of: current) else { return false }
        return i < orderedFields.count - 1
    }

    func label(for field: FocusedSetField?) -> String? {
        guard let field else { return nil }
        return labels[field]
    }

    private static func fields(for type: ExerciseType, setID: AnyHashable) -> [FocusedSetField] {
        switch type {
        case .weightAndReps:
            return [.weight(setID), .reps(setID)]
        case .bodyweightAndReps:
            return [.bodyweightModifier(setID), .reps(setID)]
        case .weightAndTime:
            return [.weight(setID), .time(setID)]
        case .distanceAndTime:
            return [.distance(setID), .time(setID)]
        case .reps:
            return [.reps(setID)]
        case .time:
            return [.time(setID)]
        }
    }

    private static func label(for field: FocusedSetField, input: SetFocusInput) -> String {
        let fieldName: String
        switch field {
        case .weight: fieldName = "Weight"
        case .reps: fieldName = "Reps"
        case .bodyweightModifier: fieldName = "Modifier"
        case .time: fieldName = "Time"
        case .distance: fieldName = "Distance"
        }
        return "Set \(input.setNumber) · \(fieldName)"
    }
}
