import Foundation
import SwiftData

@MainActor @Observable
final class SplitListViewModel {
    // MARK: - State

    private(set) var splits: [SchemaV1.Split] = []
    private(set) var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let splitService: SplitServiceProtocol
    private let router: HomeRouter

    // MARK: - Init

    init(splitService: SplitServiceProtocol, router: HomeRouter) {
        self.splitService = splitService
        self.router = router
    }

    // MARK: - Intents

    func loadSplits() async {
        isLoading = true
        errorMessage = nil
        do {
            splits = try await splitService.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func selectSplit(_ split: SchemaV1.Split) {
        router.navigateToSplitDetail(splitId: split.persistentModelID)
    }

    func createSplit() {
        router.navigateToCreateSplit()
    }

    func deleteSplit(_ split: SchemaV1.Split) async {
        errorMessage = nil
        do {
            try await splitService.delete(split)
            await loadSplits()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
