import Foundation
import SwiftData

@MainActor
final class DataService: DataServiceProtocol {
    private let modelContext: ModelContext
    private let seedingService: SeedingServiceProtocol

    init(modelContext: ModelContext, seedingService: SeedingServiceProtocol) {
        self.modelContext = modelContext
        self.seedingService = seedingService
    }

    // MARK: - Export

    func exportAllData(settings: SettingsServiceProtocol) async throws -> Data {
        let categories = try modelContext.fetch(FetchDescriptor<SchemaV1.ExerciseCategory>())
        let exercises = try modelContext.fetch(FetchDescriptor<SchemaV1.Exercise>())
        let templates = try modelContext.fetch(FetchDescriptor<SchemaV1.WorkoutTemplate>())
        let splits = try modelContext.fetch(FetchDescriptor<SchemaV1.Split>())
        let workouts = try modelContext.fetch(FetchDescriptor<SchemaV1.Workout>())

        let container = ExportContainer(
            metadata: ExportMetadata(
                exportDate: Date(),
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
                schemaVersion: "1.0.0"
            ),
            settings: SettingsExportDTO(
                units: settings.units,
                distanceUnits: settings.distanceUnits,
                appearance: settings.appearance
            ),
            categories: categories.map { mapCategory($0) },
            exercises: exercises.map { mapExercise($0) },
            templates: templates.map { mapTemplate($0) },
            splits: splits.map { mapSplit($0) },
            workouts: workouts.map { mapWorkout($0) }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        do {
            return try encoder.encode(container)
        } catch {
            throw ServiceError.exportFailed(error.localizedDescription)
        }
    }

    // MARK: - Import

    func importAllData(from data: Data, settings: SettingsServiceProtocol) async throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let container: ExportContainer
        do {
            container = try decoder.decode(ExportContainer.self, from: data)
        } catch {
            throw ServiceError.importFailed("Invalid file format: \(error.localizedDescription)")
        }

        // Clear all existing data
        try deleteAllModels()

        // Insert in dependency order
        let categoryLookup = try insertCategories(container.categories)
        let exerciseLookup = try insertExercises(container.exercises, categoryLookup: categoryLookup)
        let templateLookup = try insertTemplates(container.templates, exerciseLookup: exerciseLookup)
        try insertSplits(container.splits, templateLookup: templateLookup)
        try insertWorkouts(container.workouts, exerciseLookup: exerciseLookup, templateLookup: templateLookup)

        // Recalculate cached exercise stats from imported workout data
        try recalculateExerciseStats(exerciseLookup: exerciseLookup)

        try modelContext.save()

        // Apply imported settings
        settings.units = container.settings.units
        settings.distanceUnits = container.settings.distanceUnits
        settings.appearance = container.settings.appearance
    }

    // MARK: - Reset

    func resetAllData(settings: SettingsServiceProtocol) async throws {
        try deleteAllModels()
        try modelContext.save()

        // Reset settings to defaults
        settings.units = .lbs
        settings.distanceUnits = .mi
        settings.appearance = .system
        settings.activeSplitId = nil

        // Reset seeding flag and re-seed
        seedingService.resetSeedingFlag()
        try await seedingService.seedIfNeeded()
    }

    // MARK: - Export Mappers

    private func mapCategory(_ category: SchemaV1.ExerciseCategory) -> CategoryExportDTO {
        CategoryExportDTO(
            id: category.id,
            name: category.name,
            isDefault: category.isDefault,
            order: category.order
        )
    }

    private func mapExercise(_ exercise: SchemaV1.Exercise) -> ExerciseExportDTO {
        ExerciseExportDTO(
            id: exercise.id,
            name: exercise.name,
            type: exercise.type,
            notes: exercise.notes,
            isFavorite: exercise.isFavorite,
            isArchived: exercise.isArchived,
            createdAt: exercise.createdAt,
            preferredWeightUnit: exercise.preferredWeightUnit,
            preferredDistanceUnit: exercise.preferredDistanceUnit,
            categoryIds: exercise.categories.map(\.id)
        )
    }

    private func mapTemplate(_ template: SchemaV1.WorkoutTemplate) -> TemplateExportDTO {
        TemplateExportDTO(
            id: template.id,
            name: template.name,
            notes: template.notes,
            exercises: template.templateExercises
                .sorted { $0.order < $1.order }
                .map { templateExercise in
                    TemplateExerciseExportDTO(
                        id: templateExercise.id,
                        order: templateExercise.order,
                        notes: templateExercise.notes,
                        exerciseId: templateExercise.exercise?.id,
                        sets: templateExercise.sets
                            .sorted { $0.order < $1.order }
                            .map { set in
                                TemplateSetExportDTO(
                                    id: set.id,
                                    order: set.order,
                                    weight: set.weight,
                                    reps: set.reps,
                                    bodyweightModifier: set.bodyweightModifier,
                                    time: set.time,
                                    distance: set.distance,
                                    notes: set.notes
                                )
                            }
                    )
                }
        )
    }

    private func mapSplit(_ split: SchemaV1.Split) -> SplitExportDTO {
        SplitExportDTO(
            id: split.id,
            name: split.name,
            notes: split.notes,
            createdAt: split.createdAt,
            days: split.days
                .sorted { $0.order < $1.order }
                .map { day in
                    SplitDayExportDTO(
                        id: day.id,
                        name: day.name,
                        order: day.order,
                        isCompletedInCycle: day.isCompletedInCycle,
                        assignedWorkoutIds: day.assignedWorkouts.map(\.id)
                    )
                }
        )
    }

    private func mapWorkout(_ workout: SchemaV1.Workout) -> WorkoutExportDTO {
        WorkoutExportDTO(
            id: workout.id,
            startedAt: workout.startedAt,
            completedAt: workout.completedAt,
            statusValue: workout.statusValue,
            notes: workout.notes,
            templateId: workout.fromTemplate?.id,
            exercises: workout.loggedExercises
                .sorted { $0.order < $1.order }
                .map { loggedExercise in
                    LoggedExerciseExportDTO(
                        id: loggedExercise.id,
                        order: loggedExercise.order,
                        notes: loggedExercise.notes,
                        exerciseId: loggedExercise.exercise?.id,
                        sets: loggedExercise.sets
                            .sorted { $0.order < $1.order }
                            .map { set in
                                LoggedSetExportDTO(
                                    id: set.id,
                                    order: set.order,
                                    weight: set.weight,
                                    reps: set.reps,
                                    bodyweightModifier: set.bodyweightModifier,
                                    time: set.time,
                                    distance: set.distance,
                                    notes: set.notes,
                                    isCompleted: set.isCompleted,
                                    weightUnit: set.weightUnit,
                                    distanceUnit: set.distanceUnit,
                                    exerciseId: set.exerciseId,
                                    completedAt: set.completedAt
                                )
                            }
                    )
                }
        )
    }

    // MARK: - Import Helpers

    private func deleteAllModels() throws {
        // Delete root entities — cascade rules handle children
        let workouts = try modelContext.fetch(FetchDescriptor<SchemaV1.Workout>())
        for workout in workouts { modelContext.delete(workout) }

        let templates = try modelContext.fetch(FetchDescriptor<SchemaV1.WorkoutTemplate>())
        for template in templates { modelContext.delete(template) }

        let splits = try modelContext.fetch(FetchDescriptor<SchemaV1.Split>())
        for split in splits { modelContext.delete(split) }

        let exercises = try modelContext.fetch(FetchDescriptor<SchemaV1.Exercise>())
        for exercise in exercises { modelContext.delete(exercise) }

        let categories = try modelContext.fetch(FetchDescriptor<SchemaV1.ExerciseCategory>())
        for category in categories { modelContext.delete(category) }

        try modelContext.save()
    }

    private func insertCategories(_ dtos: [CategoryExportDTO]) throws -> [UUID: SchemaV1.ExerciseCategory] {
        var lookup: [UUID: SchemaV1.ExerciseCategory] = [:]
        for dto in dtos {
            let category = SchemaV1.ExerciseCategory(name: dto.name, isDefault: dto.isDefault, order: dto.order)
            category.id = dto.id
            modelContext.insert(category)
            lookup[dto.id] = category
        }
        return lookup
    }

    private func insertExercises(
        _ dtos: [ExerciseExportDTO],
        categoryLookup: [UUID: SchemaV1.ExerciseCategory]
    ) throws -> [UUID: SchemaV1.Exercise] {
        var lookup: [UUID: SchemaV1.Exercise] = [:]
        for dto in dtos {
            let exercise = SchemaV1.Exercise(name: dto.name, type: dto.type, notes: dto.notes)
            exercise.id = dto.id
            exercise.isFavorite = dto.isFavorite
            exercise.isArchived = dto.isArchived
            exercise.createdAt = dto.createdAt
            exercise.preferredWeightUnit = dto.preferredWeightUnit
            exercise.preferredDistanceUnit = dto.preferredDistanceUnit
            modelContext.insert(exercise)

            for categoryId in dto.categoryIds {
                if let category = categoryLookup[categoryId] {
                    exercise.categories.append(category)
                }
            }

            lookup[dto.id] = exercise
        }
        return lookup
    }

    private func insertTemplates(
        _ dtos: [TemplateExportDTO],
        exerciseLookup: [UUID: SchemaV1.Exercise]
    ) throws -> [UUID: SchemaV1.WorkoutTemplate] {
        var lookup: [UUID: SchemaV1.WorkoutTemplate] = [:]
        for dto in dtos {
            let template = SchemaV1.WorkoutTemplate(name: dto.name, notes: dto.notes)
            template.id = dto.id
            modelContext.insert(template)

            for exerciseDTO in dto.exercises {
                guard let exercise = exerciseDTO.exerciseId.flatMap({ exerciseLookup[$0] }) else { continue }
                let templateExercise = SchemaV1.TemplateExercise(exercise: exercise, order: exerciseDTO.order)
                templateExercise.id = exerciseDTO.id
                templateExercise.notes = exerciseDTO.notes
                templateExercise.template = template
                modelContext.insert(templateExercise)

                for setDTO in exerciseDTO.sets {
                    let templateSet = SchemaV1.TemplateSet(order: setDTO.order)
                    templateSet.id = setDTO.id
                    templateSet.weight = setDTO.weight
                    templateSet.reps = setDTO.reps
                    templateSet.bodyweightModifier = setDTO.bodyweightModifier
                    templateSet.time = setDTO.time
                    templateSet.distance = setDTO.distance
                    templateSet.notes = setDTO.notes
                    templateSet.templateExercise = templateExercise
                    modelContext.insert(templateSet)
                }
            }

            lookup[dto.id] = template
        }
        return lookup
    }

    private func insertSplits(
        _ dtos: [SplitExportDTO],
        templateLookup: [UUID: SchemaV1.WorkoutTemplate]
    ) throws {
        for dto in dtos {
            let split = SchemaV1.Split(name: dto.name, notes: dto.notes)
            split.id = dto.id
            split.createdAt = dto.createdAt
            modelContext.insert(split)

            for dayDTO in dto.days {
                let day = SchemaV1.SplitDay(name: dayDTO.name, order: dayDTO.order)
                day.id = dayDTO.id
                day.isCompletedInCycle = dayDTO.isCompletedInCycle
                day.split = split
                modelContext.insert(day)

                for workoutId in dayDTO.assignedWorkoutIds {
                    if let template = templateLookup[workoutId] {
                        day.assignedWorkouts.append(template)
                    }
                }
            }
        }
    }

    private func insertWorkouts(
        _ dtos: [WorkoutExportDTO],
        exerciseLookup: [UUID: SchemaV1.Exercise],
        templateLookup: [UUID: SchemaV1.WorkoutTemplate]
    ) throws {
        for dto in dtos {
            let workout = SchemaV1.Workout(fromTemplate: dto.templateId.flatMap { templateLookup[$0] })
            workout.id = dto.id
            workout.startedAt = dto.startedAt
            workout.completedAt = dto.completedAt
            workout.statusValue = dto.statusValue
            workout.notes = dto.notes
            modelContext.insert(workout)

            for exerciseDTO in dto.exercises {
                // Exercise may be nil if it was archived/deleted before export
                let exercise = exerciseDTO.exerciseId.flatMap { exerciseLookup[$0] }
                guard let resolvedExercise = exercise ?? exerciseLookup.values.first else { continue }
                let loggedExercise = SchemaV1.LoggedExercise(exercise: resolvedExercise, order: exerciseDTO.order)
                loggedExercise.id = exerciseDTO.id
                loggedExercise.notes = exerciseDTO.notes
                loggedExercise.workout = workout
                modelContext.insert(loggedExercise)

                for setDTO in exerciseDTO.sets {
                    let loggedSet = SchemaV1.LoggedSet(order: setDTO.order)
                    loggedSet.id = setDTO.id
                    loggedSet.weight = setDTO.weight
                    loggedSet.reps = setDTO.reps
                    loggedSet.bodyweightModifier = setDTO.bodyweightModifier
                    loggedSet.time = setDTO.time
                    loggedSet.distance = setDTO.distance
                    loggedSet.notes = setDTO.notes
                    loggedSet.isCompleted = setDTO.isCompleted
                    loggedSet.weightUnit = setDTO.weightUnit
                    loggedSet.distanceUnit = setDTO.distanceUnit
                    loggedSet.exerciseId = setDTO.exerciseId
                    loggedSet.completedAt = setDTO.completedAt
                    loggedSet.loggedExercise = loggedExercise
                    modelContext.insert(loggedSet)
                }
            }
        }
    }

    // MARK: - Stats Recalculation

    private func recalculateExerciseStats(exerciseLookup: [UUID: SchemaV1.Exercise]) throws {
        // Reset all cached stats
        for exercise in exerciseLookup.values {
            exercise.lastPerformedAt = nil
            exercise.hasCompletedWorkout = false
            exercise.totalVolume = 0
            exercise.totalVolumeUnit = nil
            exercise.resetPRCache()
        }

        // Fetch all completed workouts and recalculate
        let completedStatus = WorkoutStatus.completed.rawValue
        var descriptor = FetchDescriptor<SchemaV1.Workout>()
        descriptor.predicate = #Predicate<SchemaV1.Workout> { workout in
            workout.statusValue == completedStatus
        }
        let workouts = try modelContext.fetch(descriptor)

        for workout in workouts {
            guard let completedAt = workout.completedAt else { continue }

            for loggedExercise in workout.loggedExercises {
                guard let exercise = loggedExercise.exercise else { continue }

                // Update last performed
                if exercise.lastPerformedAt == nil || completedAt > exercise.lastPerformedAt! {
                    exercise.lastPerformedAt = completedAt
                }
                exercise.hasCompletedWorkout = true

                // Calculate volume
                var sessionVolume: Double = 0
                let sessionWeightUnit = loggedExercise.sets.first?.resolvedWeightUnit

                for set in loggedExercise.sets {
                    if let weight = set.weight, let reps = set.reps {
                        sessionVolume += weight * Double(reps)
                    }

                    // Check PRs
                    if exercise.shouldUpdatePR(with: set) {
                        exercise.applyPR(from: set, completedAt: completedAt)
                    }
                }

                // Accumulate volume with unit conversion
                if let sessionUnit = sessionWeightUnit, sessionVolume > 0 {
                    if let existingUnit = exercise.resolvedTotalVolumeUnit, existingUnit != sessionUnit {
                        sessionVolume = sessionVolume.convert(from: sessionUnit, to: existingUnit)
                    } else if exercise.totalVolumeUnit == nil {
                        exercise.totalVolumeUnit = sessionUnit.rawValue
                    }
                }
                exercise.totalVolume += sessionVolume
            }
        }
    }

}
