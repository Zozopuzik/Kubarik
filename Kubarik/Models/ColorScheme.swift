//
//  ColorScheme.swift
//  Kubarik
//
//  Named palette presets ("skin sets"). The active set determines which
//  colors are sampled when a new piece is generated. Future feature: a
//  full-board clear unlocks a new set.
//

import Foundation

enum ColorScheme: String, CaseIterable {
    /// Default set — uses all 7 tile colors from the design system.
    case classic

    /// Locked / preview placeholders — to be designed later.
    case sunset
    case ocean

    var tileColors: [TileColor] {
        switch self {
        case .classic:
            return [.coral, .turquoise, .lavender, .mint, .amber, .pink, .cornflower]
        case .sunset:
            return [.coral, .amber, .pink]
        case .ocean:
            return [.turquoise, .cornflower, .mint]
        }
    }
}
