//
//  WelcomeData.swift
//  Kubarik
//
//  Static data for the welcome screen — letter logo and decorative
//  background cubes. Coordinates assume a 390pt-wide canvas (iPhone 14/15).
//

import SwiftUI

struct WelcomeLetter: Identifiable {
    let id = UUID()
    let character: String
    let color: TileColor
    let rotation: Double
}

struct WelcomeCube: Identifiable {
    enum Edge {
        case left, right, top, bottom

        var offset: CGSize {
            switch self {
            case .left:   return CGSize(width: -180, height: 0)
            case .right:  return CGSize(width:  180, height: 0)
            case .top:    return CGSize(width:  0,   height: -160)
            case .bottom: return CGSize(width:  0,   height:  160)
            }
        }
    }

    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let rotation: Double
    let color: TileColor
    let opacity: Double
    let from: Edge
}

enum WelcomeData {
    static let letters: [WelcomeLetter] = [
        .init(character: "K", color: .coral,      rotation: -4),
        .init(character: "U", color: .amber,      rotation:  2),
        .init(character: "B", color: .turquoise,  rotation: -2),
        .init(character: "A", color: .lavender,   rotation:  3),
        .init(character: "R", color: .mint,       rotation:  3),
        .init(character: "I", color: .pink,       rotation: -3),
        .init(character: "K", color: .cornflower, rotation:  4),
        .init(character: "I", color: .coral,      rotation: -2),
    ]

    static let cubes: [WelcomeCube] = [
        .init(x: 24,  y: 86,  size: 32, rotation: -14, color: .mint,       opacity: 1.0, from: .left),
        .init(x: 78,  y: 70,  size: 22, rotation:  12, color: .amber,      opacity: 1.0, from: .top),
        .init(x: 330, y: 90,  size: 38, rotation:  18, color: .lavender,   opacity: 1.0, from: .right),
        .init(x: 296, y: 70,  size: 22, rotation: -22, color: .pink,       opacity: 1.0, from: .top),
        .init(x: 358, y: 446, size: 28, rotation:  22, color: .turquoise,  opacity: 0.9, from: .right),
        .init(x: 18,  y: 462, size: 32, rotation: -12, color: .coral,      opacity: 0.9, from: .left),
        .init(x: 348, y: 612, size: 22, rotation:   6, color: .amber,      opacity: 0.7, from: .right),
        .init(x: 14,  y: 628, size: 26, rotation: -18, color: .cornflower, opacity: 0.7, from: .left),
    ]
}
