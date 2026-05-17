//
//  PlayButton.swift
//  Kubarik
//
//  Big primary CTA — chunky tile button with a bottom edge that
//  compresses when pressed (the whole face slides down onto its edge).
//

import SwiftUI

struct PlayButton: View {
    var color: TileColor = .mint
    var label: String = "PLAY"
    var width: CGFloat = 252
    /// If non-nil, after this delay (seconds) the button plays a short "look
    /// at me" pulse — used on the welcome screen once the entrance animation
    /// has settled, to draw the user's eye to the CTA.
    var pulseAfter: TimeInterval? = nil
    var action: () -> Void = {}

    @State private var pressed = false
    @State private var pulseScale: CGFloat = 1.0

    private let restingDepth: CGFloat = 8
    private let pressedDepth: CGFloat = 2
    private let height: CGFloat = 76
    private let radius: CGFloat = 26

    var body: some View {
        let d = pressed ? pressedDepth : restingDepth

        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(color.top)
            .frame(width: width, height: height)
            .overlay(alignment: .top) {
                Capsule()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: width - 36, height: 12)
                    .blur(radius: 2)
                    .padding(.top, 8)
            }
            .overlay {
                Text(label)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .tracking(2.4)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.08), radius: 0, x: 0, y: 1)
            }
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(color.edge)
                    .frame(width: width, height: height)
                    .offset(y: d)
            )
            .shadow(
                color: Color(red: 40/255, green: 20/255, blue: 10/255).opacity(0.18),
                radius: pressed ? 10 : 22,
                x: 0,
                y: pressed ? 4 : 14
            )
            .scaleEffect(pulseScale)
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
            .onAppear {
                guard let delay = pulseAfter else { return }
                Task { await playAttentionPulse(initialDelay: delay) }
            }
    }

    @MainActor
    private func playAttentionPulse(initialDelay: TimeInterval) async {
        try? await Task.sleep(for: .seconds(initialDelay))
        for _ in 0..<2 {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.5)) {
                pulseScale = 1.06
            }
            try? await Task.sleep(for: .milliseconds(280))
            withAnimation(.spring(response: 0.36, dampingFraction: 0.55)) {
                pulseScale = 1.0
            }
            try? await Task.sleep(for: .milliseconds(420))
        }
    }
}

#Preview {
    ZStack {
        CreamBackground()
        PlayButton()
    }
}
