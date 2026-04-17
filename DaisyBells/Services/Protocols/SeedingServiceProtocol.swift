import Foundation

@MainActor
protocol SeedingServiceProtocol: AnyObject {
    func seedIfNeeded() async throws
    func resetSeedingFlag()
}
