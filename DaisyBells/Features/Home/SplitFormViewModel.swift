import Foundation
import SwiftData

@MainActor @Observable
final class SplitFormViewModel {
    // MARK: - State

    var name: String = ""
    private(set) var isEditing = false
    private(set) var isSaving = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let splitService: SplitServiceProtocol
    private let router: HomeRouter
    private let splitId: PersistentIdentifier?

    // MARK: - Init

    init(
        splitService: SplitServiceProtocol,
        router: HomeRouter,
        splitId: PersistentIdentifier?
    ) {
        self.splitService = splitService
        self.router = router
        self.splitId = splitId
    }

    // MARK: - Intents

    func load() async {
        guard let splitId else { return }

        isEditing = true
        errorMessage = nil

        guard let split = splitService.fetch(by: splitId) else {
            errorMessage = "Split not found"
            return
        }

        name = split.name
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
            if let splitId {
                guard let split = splitService.fetch(by: splitId) else {
                    errorMessage = "Split not found"
                    isSaving = false
                    return
                }
                split.name = name
                try await splitService.update(split)
            } else {
                _ = try await splitService.create(name: name)
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
