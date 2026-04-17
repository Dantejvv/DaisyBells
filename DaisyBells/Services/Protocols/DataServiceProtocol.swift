import Foundation

@MainActor
protocol DataServiceProtocol: AnyObject {
    func exportAllData(settings: SettingsServiceProtocol) async throws -> Data
    func importAllData(from data: Data, settings: SettingsServiceProtocol) async throws
    func resetAllData(settings: SettingsServiceProtocol) async throws
}
