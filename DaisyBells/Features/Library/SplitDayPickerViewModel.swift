import Foundation
import SwiftData

@MainActor @Observable
final class SplitDayPickerViewModel {
    // MARK: - State

    private(set) var splits: [SchemaV1.Split] = []
    private(set) var isLoading = false

    // MARK: - Dependencies

    private let splitService: SplitServiceProtocol
    private let onSelect: (PersistentIdentifier) -> Void

    // MARK: - Init

    init(
        splitService: SplitServiceProtocol,
        onSelect: @escaping (PersistentIdentifier) -> Void
    ) {
        self.splitService = splitService
        self.onSelect = onSelect
    }

    // MARK: - Intents

    func loadSplits() async {
        isLoading = true
        do {
            splits = try await splitService.fetchAll()
        } catch {
            splits = []
        }
        isLoading = false
    }

    func selectDay(_ day: SchemaV1.SplitDay) {
        onSelect(day.persistentModelID)
    }
}
