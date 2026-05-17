//
//  Preferences.swift
//  Kubarik
//
//  User-facing settings persisted in UserDefaults. Music, haptics, etc.
//  Sound effects toggle was intentionally removed at user request — kept
//  the others so audio settings still feel populated.
//

import Foundation
import Observation

@Observable
final class PreferencesStore {
    private let defaults = UserDefaults.standard

    var music: Bool {
        didSet { defaults.set(music, forKey: Keys.music) }
    }

    var hapticLevel: HapticLevel {
        didSet { defaults.set(hapticLevel.rawValue, forKey: Keys.hapticLevel) }
    }

    var boardTheme: String {
        didSet { defaults.set(boardTheme, forKey: Keys.boardTheme) }
    }

    init() {
        self.music = defaults.object(forKey: Keys.music) as? Bool ?? true
        let hapticRaw = defaults.string(forKey: Keys.hapticLevel) ?? HapticLevel.medium.rawValue
        self.hapticLevel = HapticLevel(rawValue: hapticRaw) ?? .medium
        self.boardTheme = defaults.string(forKey: Keys.boardTheme) ?? "classic"
    }

    private enum Keys {
        static let music = "kubarik.prefs.music"
        static let hapticLevel = "kubarik.prefs.hapticLevel"
        static let boardTheme = "kubarik.prefs.boardTheme"
    }
}
