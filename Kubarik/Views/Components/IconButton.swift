//
//  IconButton.swift
//  Kubarik
//
//  Small round button using the same chunky tile language as PlayButton —
//  white-ish face, brown text, edge below that compresses when pressed.
//

import SwiftUI

struct IconButton<Content: View>: View {
    var size: CGFloat = 52
    var action: () -> Void = {}
    @ViewBuilder var content: () -> Content

    @State private var pressed = false

    private let restingDepth: CGFloat = 4
    private let pressedDepth: CGFloat = 1
    private let radius: CGFloat = 18

    var body: some View {
        let d = pressed ? pressedDepth : restingDepth

        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(Palette.iconBtnBackground)
            .frame(width: size, height: size)
            .overlay {
                content()
                    .foregroundStyle(Palette.iconBtnText)
            }
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Palette.iconBtnEdge)
                    .frame(width: size, height: size)
                    .offset(y: d)
            )
            .shadow(
            color: Color(red: 120/255, green: 80/255, blue: 40/255).opacity(0.08),
            radius: pressed ? 4 : 12,
            x: 0,
            y: pressed ? 2 : 6
        )
        .contentShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !pressed {
                        withAnimation(.easeOut(duration: 0.09)) { pressed = true }
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeOut(duration: 0.09)) { pressed = false }
                    action()
                }
        )
    }
}

#Preview {
    ZStack {
        CreamBackground()
        HStack(spacing: 18) {
            IconButton { Image(systemName: "gearshape.fill").font(.system(size: 22, weight: .semibold)) }
            IconButton { Image(systemName: "speaker.wave.2.fill").font(.system(size: 22, weight: .semibold)) }
            IconButton { Image(systemName: "trophy.fill").font(.system(size: 22, weight: .semibold)) }
        }
    }
}
