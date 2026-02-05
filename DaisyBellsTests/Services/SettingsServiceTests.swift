import Testing
import Foundation
@testable import DaisyBells

@Suite(.serialized)
struct SettingsServiceTests {

    @Test @MainActor
    func unitsDefaultsToLbs() {
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let service = SettingsService(userDefaults: userDefaults)

        #expect(service.units == .lbs)
    }

    @Test @MainActor
    func unitsPersists() {
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let service = SettingsService(userDefaults: userDefaults)

        service.units = .kg

        #expect(service.units == .kg)
    }

    @Test @MainActor
    func appearanceDefaultsToSystem() {
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let service = SettingsService(userDefaults: userDefaults)

        #expect(service.appearance == .system)
    }

    @Test @MainActor
    func appearancePersists() {
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let service = SettingsService(userDefaults: userDefaults)

        service.appearance = .dark

        #expect(service.appearance == .dark)
    }

    @Test @MainActor
    func settingsAreStoredInUserDefaults() {
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let service = SettingsService(userDefaults: userDefaults)

        service.units = .kg
        service.appearance = .light

        #expect(userDefaults.string(forKey: "settings.units") == "kg")
        #expect(userDefaults.string(forKey: "settings.appearance") == "light")
    }
}
