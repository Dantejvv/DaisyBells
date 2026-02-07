import Foundation

@MainActor @Observable
final class SettingsViewModel {
    // MARK: - State

    private(set) var units: Units = .lbs
    private(set) var appearance: Appearance = .system
    private(set) var appVersion: String = ""
    private(set) var isExporting = false
    private(set) var isImporting = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let settingsService: SettingsServiceProtocol

    // MARK: - Init

    init(settingsService: SettingsServiceProtocol) {
        self.settingsService = settingsService
    }

    // MARK: - Intents

    func loadSettings() {
        units = settingsService.units
        appearance = settingsService.appearance
        appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    func updateUnits(_ newUnits: Units) {
        settingsService.units = newUnits
        units = newUnits
    }

    func updateAppearance(_ newAppearance: Appearance) {
        settingsService.appearance = newAppearance
        appearance = newAppearance
    }

    func exportData() async {
        // Phase 6 feature - stub for now
        isExporting = true
        errorMessage = nil
        // TODO: Implement export to JSON
        isExporting = false
    }

    func importData(url: URL) async {
        // Phase 6 feature - stub for now
        isImporting = true
        errorMessage = nil
        // TODO: Implement import from JSON
        isImporting = false
    }

    func resetData() async {
        // Phase 6 feature - stub for now
        errorMessage = nil
        // TODO: Implement data reset
    }
}
