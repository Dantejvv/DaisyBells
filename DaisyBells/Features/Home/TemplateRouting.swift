import SwiftData

@MainActor
protocol TemplateRouting: AnyObject {
    func navigateToTemplateDetail(templateId: PersistentIdentifier)
    func presentTemplateForm(templateId: PersistentIdentifier?)
    func dismissSheet()
    func pop()
}
