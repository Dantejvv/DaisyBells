import Foundation

protocol SettingsServiceProtocol: AnyObject {
    var units: Units { get set }
    var appearance: Appearance { get set }
}
