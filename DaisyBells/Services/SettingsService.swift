import Foundation

@MainActor
final class SettingsService: SettingsServiceProtocol {
    private let userDefaults: UserDefaults

    private enum Keys {
        static let units = "settings.units"
        static let appearance = "settings.appearance"
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var units: Units {
        get {
            guard let rawValue = userDefaults.string(forKey: Keys.units),
                  let value = Units(rawValue: rawValue) else {
                return .lbs
            }
            return value
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Keys.units)
        }
    }

    var appearance: Appearance {
        get {
            guard let rawValue = userDefaults.string(forKey: Keys.appearance),
                  let value = Appearance(rawValue: rawValue) else {
                return .system
            }
            return value
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Keys.appearance)
        }
    }
}
