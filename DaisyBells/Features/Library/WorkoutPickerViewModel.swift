import Foundation
import SwiftData

@MainActor @Observable
final class WorkoutPickerViewModel {
    // MARK: - State

    private(set) var templates: [SchemaV1.WorkoutTemplate] = []
    var searchQuery: String = ""
    private(set) var isLoading = false

    // MARK: - Dependencies

    private let templateService: TemplateServiceProtocol
    private let onSelect: (PersistentIdentifier) -> Void
    private var allTemplates: [SchemaV1.WorkoutTemplate] = []

    // MARK: - Init

    init(
        templateService: TemplateServiceProtocol,
        onSelect: @escaping (PersistentIdentifier) -> Void
    ) {
        self.templateService = templateService
        self.onSelect = onSelect
    }

    // MARK: - Intents

    func loadTemplates() async {
        isLoading = true
        do {
            allTemplates = try await templateService.fetchAll()
            applyFilters()
        } catch {
            templates = []
        }
        isLoading = false
    }

    func search(query: String) {
        searchQuery = query
        applyFilters()
    }

    func selectTemplate(_ template: SchemaV1.WorkoutTemplate) {
        onSelect(template.persistentModelID)
    }

    // MARK: - Private

    private func applyFilters() {
        var filtered = allTemplates

        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            filtered = filtered.filter { $0.name.lowercased().contains(query) }
        }

        templates = filtered.sorted { $0.name < $1.name }
    }
}
