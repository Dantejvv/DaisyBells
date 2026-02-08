import Foundation
import SwiftData

@MainActor @Observable
final class SplitDayFormViewModel {
    // MARK: - State

    var name: String = ""
    private(set) var isEditing = false
    private(set) var isSaving = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let splitDayService: SplitDayServiceProtocol
    private let splitService: SplitServiceProtocol
    private let router: HomeRouter
    private let splitId: PersistentIdentifier
    private let dayId: PersistentIdentifier?

    // MARK: - Init

    init(
        splitDayService: SplitDayServiceProtocol,
        splitService: SplitServiceProtocol,
        router: HomeRouter,
        splitId: PersistentIdentifier,
        dayId: PersistentIdentifier?
    ) {
        self.splitDayService = splitDayService
        self.splitService = splitService
        self.router = router
        self.splitId = splitId
        self.dayId = dayId
    }

    // MARK: - Intents

    func load() async {
        guard let dayId else { return }

        isEditing = true
        errorMessage = nil

        guard let day = splitDayService.fetch(by: dayId) else {
            errorMessage = "Split day not found"
            return
        }

        name = day.name
    }

    func updateName(_ name: String) {
        self.name = name
    }

    func save() async {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Name cannot be empty"
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            if let dayId {
                guard let day = splitDayService.fetch(by: dayId) else {
                    errorMessage = "Split day not found"
                    isSaving = false
                    return
                }
                day.name = name
                try await splitDayService.update(day)
            } else {
                guard let split = splitService.fetch(by: splitId) else {
                    errorMessage = "Split not found"
                    isSaving = false
                    return
                }
                _ = try await splitDayService.create(name: name, split: split)
            }
            router.pop()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }

    func cancel() {
        router.pop()
    }
}
