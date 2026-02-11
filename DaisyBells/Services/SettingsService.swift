import Foundation

@MainActor
final class SettingsService: SettingsServiceProtocol {
    private let userDefaults: UserDefaults

    private enum Keys {
        static let units = "settings.units"
        static let appearance = "settings.appearance"
        static let activeSplitId = "settings.activeSplitId"
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

    var activeSplitId: UUID? {
        get {
            guard let string = userDefaults.string(forKey: Keys.activeSplitId) else {
                return nil
            }
            return UUID(uuidString: string)
        }
        set {
            if let id = newValue {
                userDefaults.set(id.uuidString, forKey: Keys.activeSplitId)
            } else {
                userDefaults.removeObject(forKey: Keys.activeSplitId)
            }
        }
    }
}
