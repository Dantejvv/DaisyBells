import Foundation
import SwiftData
@testable import DaisyBells

/// Creates an isolated in-memory ModelContainer for testing
@MainActor
func makeTestModelContainer() throws -> ModelContainer {
    let schema = Schema(versionedSchema: SchemaV1.self)
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, configurations: config)
}
