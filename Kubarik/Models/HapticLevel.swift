//
//  HapticLevel.swift
//  Kubarik
//
//  Three-way user preference for haptic intensity. HapticEngine reads
//  this and decides how heavy / how many pulses to fire per event.
//

import Foundation

enum HapticLevel: String, CaseIterable, Codable {
    case off
    case medium
    case high

    var label: String {
        switch self {
        case .off:    return "Off"
        case .medium: return "Medium"
        case .high:   return "High"
        }
    }
}
