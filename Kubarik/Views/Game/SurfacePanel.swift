//
//  SurfacePanel.swift
//  Kubarik
//
//  Reusable game-surface panel. The board and the tray both sit on one
//  of these — a solid cream-tinted platform with a chunky bottom edge,
//  a thin warm border, a top highlight rim, and a cast shadow. The
//  visual depth matches the tile-style chrome used everywhere else so
//  every surface in the game reads like it's cut from the same wood.
//

import SwiftUI

struct SurfacePanel: View {
    var cornerRadius: CGFloat = 22

    /// Width of the chunky bottom edge that fakes physical thickness.
    var edgeDepth: CGFloat = 10

    /// Solid platform fill — slightly warmer than the screen background
    /// so the surface reads as a distinct object, not a translucent overlay.
    private let faceColor = Color(hex: 0xFFE7C2)
    private let edgeColor = Color(hex: 0xB48C5A)
    private let borderColor = Color(hex: 0xA67E55)

    var body: some View {
        ZStack {
            // 1. Bottom edge — solid colored slab offset down from the face.
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(edgeColor.opacity(0.55))
                .offset(y: edgeDepth)

            // 2. Main face — solid cream fill.
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(faceColor)

            // 3. Outer border — defines the rim against any wallpaper.
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(borderColor.opacity(0.28), lineWidth: 1.5)

            // 4. Top rim — bright thin highlight along the upper edge.
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.95),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .center
                    ),
                    lineWidth: 2
                )

            // 5. Bottom inner shadow — recessed feel relative to the rim.
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color(hex: 0x6B4A2A).opacity(0.16)
                        ],
                        startPoint: .center,
                        endPoint: .bottom
                    ),
                    lineWidth: 2
                )
        }
        .shadow(color: Color(hex: 0x6B4A2A).opacity(0.18), radius: 20, x: 0, y: 14)
    }
}

#Preview {
    ZStack {
        CreamBackground()
        VStack(spacing: 24) {
            SurfacePanel().frame(width: 320, height: 320)
            SurfacePanel().frame(width: 320, height: 120)
        }
    }
}
