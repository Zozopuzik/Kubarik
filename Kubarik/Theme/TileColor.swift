//
//  TileColor.swift
//  Kubarik
//

import SwiftUI

enum TileColor: CaseIterable {
    case coral
    case turquoise
    case lavender
    case mint
    case amber
    case pink
    case cornflower

    var top: Color {
        switch self {
        case .coral:      return Color(hex: 0xFF7864)
        case .turquoise:  return Color(hex: 0x3FCCC4)
        case .lavender:   return Color(hex: 0xB59CEC)
        case .mint:       return Color(hex: 0x86E0AC)
        case .amber:      return Color(hex: 0xFFC560)
        case .pink:       return Color(hex: 0xFF95B4)
        case .cornflower: return Color(hex: 0x7BA9F0)
        }
    }

    var edge: Color {
        switch self {
        case .coral:      return Color(hex: 0xD85440)
        case .turquoise:  return Color(hex: 0x1FA098)
        case .lavender:   return Color(hex: 0x8A6DD0)
        case .mint:       return Color(hex: 0x56B584)
        case .amber:      return Color(hex: 0xE0993B)
        case .pink:       return Color(hex: 0xD86A8E)
        case .cornflower: return Color(hex: 0x4F82CC)
        }
    }
}
