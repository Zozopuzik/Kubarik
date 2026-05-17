//
//  TileView.swift
//  Kubarik
//
//  The visual atom of the game: a "cube tile" with a flat top, a solid
//  bottom edge that fakes 3D depth, and a soft cast shadow underneath.
//  Used everywhere — board cells, tray pieces, decorative confetti,
//  and the letter logo on the welcome screen.
//

import SwiftUI

struct TileView<Content: View>: View {
    var color: TileColor = .coral
    var size: CGFloat = 56
    var radius: CGFloat? = nil
    var depth: CGFloat? = nil
    var rotation: Double = 0
    var cast: Bool = true
    @ViewBuilder var content: () -> Content

    private var resolvedRadius: CGFloat {
        radius ?? (size * 0.28).rounded()
    }

    private var resolvedDepth: CGFloat {
        depth ?? max(3, (size * 0.13).rounded())
    }

    var body: some View {
        let r = resolvedRadius
        let d = resolvedDepth

        RoundedRectangle(cornerRadius: r, style: .continuous)
            .fill(color.top)
            .frame(width: size, height: size)
            .overlay(
                LinearGradient(
                    colors: [Color.white.opacity(0.22), .clear],
                    startPoint: .top,
                    endPoint: .center
                )
                .blendMode(.plusLighter)
                .mask(RoundedRectangle(cornerRadius: r, style: .continuous))
            )
            .overlay(content().foregroundStyle(.white))
            .background(
                RoundedRectangle(cornerRadius: r, style: .continuous)
                    .fill(color.edge)
                    .frame(width: size, height: size)
                    .offset(y: d)
            )
            .shadow(
                color: cast ? Color(red: 40/255, green: 20/255, blue: 10/255).opacity(0.14) : .clear,
                radius: 12,
                x: 0,
                y: d + 4
            )
            .rotationEffect(.degrees(rotation))
    }
}

extension TileView where Content == EmptyView {
    init(
        color: TileColor = .coral,
        size: CGFloat = 56,
        radius: CGFloat? = nil,
        depth: CGFloat? = nil,
        rotation: Double = 0,
        cast: Bool = true
    ) {
        self.color = color
        self.size = size
        self.radius = radius
        self.depth = depth
        self.rotation = rotation
        self.cast = cast
        self.content = { EmptyView() }
    }
}

#Preview {
    ZStack {
        CreamBackground()
        VStack(spacing: 24) {
            HStack(spacing: 12) {
                TileView(color: .coral, size: 64, rotation: -4) {
                    Text("K").font(.system(size: 40, weight: .bold, design: .rounded))
                }
                TileView(color: .amber, size: 64, rotation: 2) {
                    Text("U").font(.system(size: 40, weight: .bold, design: .rounded))
                }
                TileView(color: .turquoise, size: 64, rotation: -2) {
                    Text("B").font(.system(size: 40, weight: .bold, design: .rounded))
                }
            }
            HStack(spacing: 12) {
                TileView(color: .mint, size: 40)
                TileView(color: .pink, size: 40, rotation: 10)
                TileView(color: .lavender, size: 40, rotation: -10)
                TileView(color: .cornflower, size: 40)
            }
        }
    }
}
