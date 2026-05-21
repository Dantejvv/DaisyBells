import Foundation
import SwiftData

@MainActor
final class SeedingService: SeedingServiceProtocol {
    private let modelContext: ModelContext

    private enum Keys {
        static let hasSeeded = "app.hasSeededDefaultData"
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func resetSeedingFlag() {
        UserDefaults.standard.removeObject(forKey: Keys.hasSeeded)
    }

    func seedIfNeeded() async throws {
        // Skip seeding during unit tests
        #if DEBUG
        if NSClassFromString("XCTestCase") != nil {
            return
        }
        #endif

        let userDefaults = UserDefaults.standard
        guard !userDefaults.bool(forKey: Keys.hasSeeded) else {
            return
        }

        try await seedDefaultCategories()
        try await seedDefaultExercises()

        userDefaults.set(true, forKey: Keys.hasSeeded)
    }

    private func seedDefaultCategories() async throws {
        guard let url = Bundle.main.url(forResource: "categories", withExtension: "json") else {
            throw ServiceError.notFound("categories.json")
        }

        let data = try Data(contentsOf: url)
        let categoryDTOs = try JSONDecoder().decode([CategoryDTO].self, from: data)

        for dto in categoryDTOs {
            let category = SchemaV1.ExerciseCategory(name: dto.name, isDefault: dto.isDefault, order: dto.order)
            modelContext.insert(category)
        }

        try modelContext.save()
    }

    private func seedDefaultExercises() async throws {
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json") else {
            throw ServiceError.notFound("exercises.json")
        }

        let data = try Data(contentsOf: url)
        let exerciseDTOs = try JSONDecoder().decode([ExerciseDTO].self, from: data)

        let descriptor = FetchDescriptor<SchemaV1.ExerciseCategory>()
        let categories = try modelContext.fetch(descriptor)
        let categoryMap = Dictionary(uniqueKeysWithValues: categories.map { ($0.name, $0) })

        let existing = try modelContext.fetch(FetchDescriptor<SchemaV1.Exercise>())
        var seen: Set<String> = Set(existing.map { Self.dedupKey(name: $0.name, type: $0.type) })

        for dto in exerciseDTOs {
            let key = Self.dedupKey(name: dto.name, type: dto.type)
            guard !seen.contains(key) else { continue }
            seen.insert(key)

            let exercise = SchemaV1.Exercise(name: dto.name, type: dto.type)
            modelContext.insert(exercise)

            for categoryName in dto.categories {
                if let category = categoryMap[categoryName] {
                    exercise.categories.append(category)
                }
            }
        }

        try modelContext.save()
    }

    private static func dedupKey(name: String, type: ExerciseType) -> String {
        "\(ExerciseService.normalize(name))|\(type.rawValue)"
    }
}

// MARK: - DTOs for JSON Parsing

private struct CategoryDTO: Decodable {
    let name: String
    let isDefault: Bool
    let order: Int
}

private struct ExerciseDTO: Decodable {
    let name: String
    let type: ExerciseType
    let categories: [String]
}
