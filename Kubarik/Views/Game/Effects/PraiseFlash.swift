//
//  PraiseFlash.swift
//  Kubarik
//
//  The big bouncy callout text ("NICE!" / "COMBO!" / "WOW!" / "ON FIRE!")
//  that pops in the middle of the screen on every line clear. Tier
//  controls size, color, and word pool.
//
//  Animation phases (mirrors the JS keyframes from the design):
//    0    ms — start: scale 0.3, rotation -10°, opacity 0
//   ~200  ms — pop:   scale 1.25, rotation -3°, opacity 1
//   ~350  ms — settle:scale 1.0, rotation 0°
//   ~750  ms — hold
//  ~1100  ms — drift up & fade
//

import SwiftUI

struct PraiseFlash: View {
    let word: String
    let tier: PraiseTier

    @State private var scale: CGFloat = 0.3
    @State private var rotation: Double = -10
    @State private var offsetY: CGFloat = 0
    @State private var opacity: Double = 0

    var body: some View {
        Text(word)
            .font(.system(size: tier.fontSize, weight: .heavy, design: .rounded))
            .tracking(tier.tracking)
            .foregroundStyle(tier.color.top)
            .shadow(color: tier.color.edge, radius: 0, x: 0, y: 2)
            .shadow(color: tier.color.edge, radius: 0, x: 0, y: 4)
            .shadow(color: tier.color.edge, radius: 0, x: 0, y: 6)
            .shadow(color: .black.opacity(0.32), radius: 22, x: 0, y: 14)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .offset(y: offsetY)
            .opacity(opacity)
            .allowsHitTesting(false)
            .onAppear { play() }
    }

    private func play() {
        // Pop in
        withAnimation(.spring(response: 0.22, dampingFraction: 0.5)) {
            scale = 1.25
            rotation = -3
            opacity = 1
        }
        // Settle
        withAnimation(.spring(response: 0.18, dampingFraction: 0.6).delay(0.20)) {
            scale = 1.0
            rotation = 0
        }
        // Hold then drift up & fade
        withAnimation(.easeIn(duration: 0.35).delay(0.75)) {
            offsetY = -40
            scale = 1.05
            opacity = 0
        }
    }
}

#Preview {
    ZStack {
        CreamBackground()
        VStack(spacing: 30) {
            ForEach(PraiseTier.allCases, id: \.rawValue) { tier in
                PraiseFlash(word: tier.randomWord, tier: tier)
            }
        }
    }
}
