import Foundation
import SwiftData

@MainActor
protocol AnalyticsServiceProtocol {
    func workoutsThisWeek() async throws -> Int
    func workoutsThisMonth() async throws -> Int
    func recentExercises(limit: Int) async throws -> [SchemaV1.Exercise]
    func personalRecords(limit: Int) async throws -> [PersonalRecord]
    func volumeForExercise(_ exercise: SchemaV1.Exercise) async throws -> Double
    func personalBestForExercise(_ exercise: SchemaV1.Exercise) async throws -> PersonalRecord?
    func lastPerformedDate(_ exercise: SchemaV1.Exercise) async throws -> Date?
    func recentSetsForExercise(_ exercise: SchemaV1.Exercise, limit: Int) async throws -> [SchemaV1.LoggedSet]
}
