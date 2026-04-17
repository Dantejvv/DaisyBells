import Foundation
import SwiftData

@MainActor @Observable
final class SplitListViewModel {
    // MARK: - State

    private(set) var splits: [SchemaV1.Split] = []
    private(set) var isLoading = false
    private(set) var activeSplitId: UUID?
    var splitPendingDelete: SchemaV1.Split?
    var errorMessage: String?

    // MARK: - Dependencies

    private let splitService: SplitServiceProtocol
    private let settingsService: SettingsServiceProtocol
    private let router: HomeRouter

    // MARK: - Init

    init(
        splitService: SplitServiceProtocol,
        settingsService: SettingsServiceProtocol,
        router: HomeRouter
    ) {
        self.splitService = splitService
        self.settingsService = settingsService
        self.router = router
    }

    // MARK: - Intents

    func loadSplits() async {
        isLoading = true
        errorMessage = nil
        activeSplitId = settingsService.activeSplitId
        do {
            splits = try await splitService.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func setActiveSplit(_ split: SchemaV1.Split) {
        if activeSplitId == split.id {
            settingsService.activeSplitId = nil
            activeSplitId = nil
        } else {
            settingsService.activeSplitId = split.id
            activeSplitId = split.id
        }
    }

    func clearActiveSplit() {
        settingsService.activeSplitId = nil
        activeSplitId = nil
    }

    func editSplit(_ split: SchemaV1.Split) {
        router.presentEditSplit(splitId: split.persistentModelID)
    }

    func createSplit() {
        router.presentCreateSplit()
    }

    // MARK: - Delete Flow

    func requestDelete(_ split: SchemaV1.Split) {
        splitPendingDelete = split
    }

    func cancelDelete() {
        splitPendingDelete = nil
    }

    func confirmDelete() async {
        guard let split = splitPendingDelete else { return }
        errorMessage = nil
        do {
            if activeSplitId == split.id {
                settingsService.activeSplitId = nil
                activeSplitId = nil
            }
            try await splitService.delete(id: split.id)
            splitPendingDelete = nil
            await loadSplits()
        } catch {
            errorMessage = error.localizedDescription
            splitPendingDelete = nil
        }
    }
}
