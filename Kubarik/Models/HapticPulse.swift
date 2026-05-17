//
//  HapticPulse.swift
//  Kubarik
//
//  Game-side description of a haptic event the UI should play. The UI
//  reads `GameState.hapticEvent` via `.sensoryFeedback(trigger:)` and
//  maps each pulse kind to a concrete SensoryFeedback at the view layer
//  (keeping UIKit/SwiftUI types out of the model).
//
//  Each pulse carries a UUID so two consecutive identical events still
//  count as a change for SwiftUI's Equatable-based trigger comparison.
//

import Foundation

struct HapticPulse: Equatable {
    enum Kind: Equatable {
        case pickup
        case placement(cells: Int)
        case linesCleared(Int)
        case fullClear
        case gameOver
    }

    let kind: Kind
    let id: UUID

    init(kind: Kind) {
        self.kind = kind
        self.id = UUID()
    }
}
