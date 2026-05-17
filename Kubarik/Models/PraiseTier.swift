//
//  PraiseTier.swift
//  Kubarik
//
//  Escalating tiers of "praise" callout shown when the player clears
//  lines. Tier rises with how many lines cleared in one move (1..4) and
//  jumps to its top rung once the combo chain reaches 3.
//

import Foundation

enum PraiseTier: Int, CaseIterable {
    case nice = 1   // 1 line
    case great      // 2 lines
    case amazing    // 3 lines
    case insane     // 4 lines
    case onFire     // combo chain >= 3 (overrides line count)

    static func evaluate(lineCount: Int, comboChain: Int) -> PraiseTier {
        if comboChain >= 3 { return .onFire }
        let clamped = min(max(lineCount, 1), 4)
        return PraiseTier(rawValue: clamped) ?? .nice
    }

    var words: [String] {
        switch self {
        case .nice:    return ["NICE!", "POP!", "CLEAR!", "SWEET!"]
        case .great:   return ["GREAT!", "COMBO!", "DOUBLE!", "NEAT!"]
        case .amazing: return ["AMAZING!", "WOW!", "TRIPLE!", "STELLAR!"]
        case .insane:  return ["INSANE!", "MEGA!", "QUAD!", "BLAST!"]
        case .onFire:  return ["ON FIRE!", "UNSTOPPABLE!", "PERFECT!", "GODLIKE!"]
        }
    }

    var randomWord: String { words.randomElement() ?? "NICE!" }

    var fontSize: CGFloat {
        switch self {
        case .nice:    return 44
        case .great:   return 54
        case .amazing: return 64
        case .insane:  return 74
        case .onFire:  return 80
        }
    }

    var color: TileColor {
        switch self {
        case .nice:    return .mint
        case .great:   return .amber
        case .amazing: return .coral
        case .insane:  return .pink
        case .onFire:  return .lavender
        }
    }

    var tracking: CGFloat {
        rawValue >= 4 ? 3 : 2
    }
}
