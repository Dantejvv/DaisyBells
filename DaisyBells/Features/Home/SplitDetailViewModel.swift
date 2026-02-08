import Foundation
import SwiftUI
import SwiftData

@MainActor @Observable
final class SplitDetailViewModel {
    // MARK: - State

    private(set) var split: SchemaV1.Split?
    private(set) var days: [SchemaV1.SplitDay] = []
    private(set) var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let splitService: SplitServiceProtocol
    private let splitDayService: SplitDayServiceProtocol
    private let router: HomeRouter
    private let splitId: PersistentIdentifier

    // MARK: - Init

    init(
        splitService: SplitServiceProtocol,
        splitDayService: SplitDayServiceProtocol,
        router: HomeRouter,
        splitId: PersistentIdentifier
    ) {
        self.splitService = splitService
        self.splitDayService = splitDayService
        self.router = router
        self.splitId = splitId
    }

    // MARK: - Intents

    func loadSplit() async {
        isLoading = true
        errorMessage = nil

        guard let splitModel = splitService.fetch(by: splitId) else {
            errorMessage = "Split not found"
            isLoading = false
            return
        }

        split = splitModel
        days = splitModel.days.sorted { $0.order < $1.order }
        isLoading = false
    }

    func editSplit() {
        router.navigateToEditSplit(splitId: splitId)
    }

    func deleteSplit() async {
        guard let split else { return }
        errorMessage = nil
        do {
            try await splitService.delete(split)
            router.pop()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addDay() {
        router.navigateToAddDay(splitId: splitId)
    }

    func selectDay(_ day: SchemaV1.SplitDay) {
        router.navigateToSplitDayDetail(dayId: day.persistentModelID)
    }

    func reorderDays(from source: IndexSet, to destination: Int) {
        days.move(fromOffsets: source, toOffset: destination)

        // Update order property for each day
        for (index, day) in days.enumerated() {
            day.order = index
        }

        Task {
            do {
                for day in days {
                    try await splitDayService.update(day)
                }
            } catch {
                errorMessage = error.localizedDescription
                await loadSplit() // Reload to restore original order
            }
        }
    }

    func deleteDay(_ day: SchemaV1.SplitDay) async {
        guard let split else { return }
        errorMessage = nil
        do {
            try await splitDayService.delete(day, from: split)
            await loadSplit()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
