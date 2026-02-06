import Foundation
import SwiftData

@MainActor @Observable
final class TemplateListViewModel {
    // MARK: - State

    private(set) var templates: [SchemaV1.WorkoutTemplate] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    // MARK: - Dependencies

    private let templateService: TemplateServiceProtocol
    private let router: LibraryRouter

    // MARK: - Init

    init(templateService: TemplateServiceProtocol, router: LibraryRouter) {
        self.templateService = templateService
        self.router = router
    }

    // MARK: - Intents

    func loadTemplates() async {
        isLoading = true
        errorMessage = nil
        do {
            templates = try await templateService.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func selectTemplate(_ template: SchemaV1.WorkoutTemplate) {
        router.navigateToTemplateDetail(templateId: template.persistentModelID)
    }

    func createTemplate() {
        router.navigateToCreateTemplate()
    }

    func deleteTemplate(_ template: SchemaV1.WorkoutTemplate) async {
        errorMessage = nil
        do {
            try await templateService.delete(template)
            await loadTemplates()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
