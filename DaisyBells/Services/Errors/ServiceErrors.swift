import Foundation

enum ServiceError: LocalizedError {
    case notFound(String)
    case saveFailed(String)
    case deleteFailed(String)
    case invalidOperation(String)
    case exportFailed(String)
    case importFailed(String)

    var errorDescription: String? {
        switch self {
        case .notFound(let entity):
            return "\(entity) not found"
        case .saveFailed(let reason):
            return "Failed to save: \(reason)"
        case .deleteFailed(let reason):
            return "Failed to delete: \(reason)"
        case .invalidOperation(let reason):
            return "Invalid operation: \(reason)"
        case .exportFailed(let reason):
            return "Export failed: \(reason)"
        case .importFailed(let reason):
            return "Import failed: \(reason)"
        }
    }
}
