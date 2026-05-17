//
//  BoardCellView.swift
//  Kubarik
//
//  A single cell on the 7×7 board. Either a placed tile (shows the
//  piece's color) or an empty slot (faint inset hint, no shadow).
//
//  Animations:
//  - Settle pop: when `isJustPlaced` is true the cell scales up from
//    0.4 → 1.18 → 1.0 with a bouncy spring, mirroring the design's
//    `kbSettle` keyframes.
//  - Will-clear pulse: when `willClear` is true the tile pulses brighter
//    and gently scales — a "you can do it" hint before the player drops.
//

import SwiftUI

struct BoardCellView: View {
    let color: TileColor?
    let size: CGFloat
    var isJustPlaced: Bool = false
    var willClear: Bool = false
    /// Color of the hovering piece — used to ghost-fill empty cells in
    /// a row or column that would clear on drop. Nil means no preview.
    var willClearColor: TileColor? = nil

    @State private var settleScale: CGFloat = 1.0
    @State private var settleOpacity: Double = 1.0
    @State private var glow: Double = 0

    var body: some View {
        Group {
            if let color {
                TileView(color: color, size: size, cast: false)
                    .scaleEffect(settleScale * (willClear ? (1.0 + 0.10 * glow) : 1.0))
                    .opacity(settleOpacity)
                    .saturation(willClear ? 1.0 + 0.6 * glow : 1.0)
                    .brightness(willClear ? 0.28 * glow : 0)
                    .shadow(
                        color: .white.opacity(willClear ? 0.95 * glow : 0),
                        radius: 14,
                        x: 0,
                        y: 0
                    )
            } else {
                emptySlot
                    .overlay(ghostFill)
            }
        }
        .onAppear { configureInitialState() }
        .onChange(of: isJustPlaced) { _, newValue in
            if newValue { playSettlePop() }
        }
        .onChange(of: willClear) { _, newValue in
            if newValue {
                startGlow()
            } else {
                stopGlow()
            }
        }
    }

    /// Faint colored tile painted on top of an empty slot when its row or
    /// column would clear on drop. Reads the full line as already-complete
    /// in the player's peripheral vision — a much louder hint than a
    /// border or glow.
    @ViewBuilder
    private var ghostFill: some View {
        if willClear, let willClearColor {
            TileView(color: willClearColor, size: size, depth: 0, cast: false)
                .opacity(0.30 + 0.30 * glow)
                .saturation(0.9)
        }
    }

    /// Empty cell — a pocket carved into the platform. Renders with a
    /// darker fill and a soft top-to-bottom shadow gradient so each slot
    /// reads as a recess the player can drop a tile into.
    private var emptySlot: some View {
        let radius = size * 0.22
        return ZStack {
            // Carved-out fill — visibly darker than the platform face.
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(Color(hex: 0x8C643C).opacity(0.18))

            // Top-to-bottom inner shadow — sells the "scooped out" feel.
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: 0x6B4A2A).opacity(0.18),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: UnitPoint(x: 0.5, y: 0.45)
                    )
                )

            // Bottom rim highlight — thin bright line along the lower edge.
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.55)
                        ],
                        startPoint: .center,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
                .blendMode(.plusLighter)
        }
        .frame(width: size, height: size)
    }

    private func configureInitialState() {
        if isJustPlaced {
            settleScale = 0.92
            settleOpacity = 0.6
            playSettlePop()
        }
        if willClear { startGlow() }
    }

    private func playSettlePop() {
        settleScale = 0.92
        settleOpacity = 0.6
        withAnimation(.spring(response: 0.14, dampingFraction: 0.6)) {
            settleScale = 1.05
            settleOpacity = 1.0
        }
        withAnimation(.spring(response: 0.18, dampingFraction: 0.8).delay(0.10)) {
            settleScale = 1.0
        }
    }

    private func startGlow() {
        withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
            glow = 1.0
        }
    }

    private func stopGlow() {
        withAnimation(.easeOut(duration: 0.2)) {
            glow = 0
        }
    }
}
