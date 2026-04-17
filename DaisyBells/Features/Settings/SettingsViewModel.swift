import Foundation
import SwiftUI

@MainActor @Observable
final class SettingsViewModel {
    // MARK: - State

    private(set) var units: Units = .lbs
    private(set) var distanceUnits: DistanceUnits = .mi
    private(set) var appearance: Appearance = .system
    private(set) var appVersion: String = ""
    private(set) var isExporting = false
    private(set) var isImporting = false
    var errorMessage: String?

    // Export state for fileExporter
    var exportDocument: JSONDocument?
    var showFileExporter = false
    var showFileImporter = false

    // MARK: - Dependencies

    private let settingsService: SettingsServiceProtocol
    private let dataService: DataServiceProtocol?
    private let onAppearanceChanged: ((Appearance) -> Void)?

    // MARK: - Init

    init(
        settingsService: SettingsServiceProtocol,
        dataService: DataServiceProtocol? = nil,
        onAppearanceChanged: ((Appearance) -> Void)? = nil
    ) {
        self.settingsService = settingsService
        self.dataService = dataService
        self.onAppearanceChanged = onAppearanceChanged
    }

    // MARK: - Intents

    func loadSettings() {
        units = settingsService.units
        distanceUnits = settingsService.distanceUnits
        appearance = settingsService.appearance
        appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    func updateUnits(_ newUnits: Units) {
        settingsService.units = newUnits
        units = newUnits
    }

    func updateDistanceUnits(_ newDistanceUnits: DistanceUnits) {
        settingsService.distanceUnits = newDistanceUnits
        distanceUnits = newDistanceUnits
    }

    func updateAppearance(_ newAppearance: Appearance) {
        settingsService.appearance = newAppearance
        onAppearanceChanged?(newAppearance)
        appearance = newAppearance
    }

    func exportData() async {
        guard let dataService else { return }
        isExporting = true
        errorMessage = nil
        do {
            let data = try await dataService.exportAllData(settings: settingsService)
            exportDocument = JSONDocument(data: data)
            showFileExporter = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isExporting = false
    }

    func importData(url: URL) async {
        guard let dataService else { return }
        isImporting = true
        errorMessage = nil
        do {
            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing { url.stopAccessingSecurityScopedResource() }
            }
            let data = try Data(contentsOf: url)
            try await dataService.importAllData(from: data, settings: settingsService)
            loadSettings()
        } catch {
            errorMessage = error.localizedDescription
        }
        isImporting = false
    }

    func resetData() async {
        guard let dataService else { return }
        errorMessage = nil
        do {
            try await dataService.resetAllData(settings: settingsService)
            loadSettings()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
