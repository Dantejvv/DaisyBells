import Foundation
import SwiftData

@MainActor
final class SeedingService {
    private let modelContext: ModelContext

    private enum Keys {
        static let hasSeeded = "app.hasSeededDefaultData"
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
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
            let category = SchemaV1.ExerciseCategory(name: dto.name, isDefault: dto.isDefault)
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

        for dto in exerciseDTOs {
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
}

// MARK: - DTOs for JSON Parsing

private struct CategoryDTO: Decodable {
    let name: String
    let isDefault: Bool
}

private struct ExerciseDTO: Decodable {
    let name: String
    let type: ExerciseType
    let categories: [String]
}
