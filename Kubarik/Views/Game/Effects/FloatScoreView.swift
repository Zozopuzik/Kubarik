//
//  FloatScoreView.swift
//  Kubarik
//
//  The "+N" pop-up that drifts upward and fades after a line clear. Shows
//  exactly how many points the clear earned so the player can feel it.
//

import SwiftUI

struct FloatScoreInstance: Identifiable, Equatable {
    let id = UUID()
    let origin: CGPoint
    let delta: Int
    let color: TileColor
}

struct FloatScoreView: View {
    let instance: FloatScoreInstance

    @State private var scale: CGFloat = 0.6
    @State private var offsetY: CGFloat = 0
    @State private var opacity: Double = 0

    var body: some View {
        Text("+\(instance.delta)")
            .font(.system(size: 30, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .shadow(color: instance.color.edge, radius: 0, x: 0, y: 2)
            .shadow(color: instance.color.edge, radius: 0, x: 0, y: 6)
            .shadow(color: .black.opacity(0.28), radius: 14, x: 0, y: 10)
            .scaleEffect(scale)
            .offset(y: offsetY)
            .opacity(opacity)
            .position(instance.origin)
            .allowsHitTesting(false)
            .onAppear { play() }
    }

    private func play() {
        // Pop in
        withAnimation(.spring(response: 0.18, dampingFraction: 0.55)) {
            scale = 1.18
            opacity = 1
        }
        // Settle slightly down (so it reads as anchored before drifting up)
        withAnimation(.easeOut(duration: 0.16).delay(0.15)) {
            scale = 1.0
            offsetY = -10
        }
        // Drift up & fade
        withAnimation(.easeIn(duration: 0.75).delay(0.30)) {
            offsetY = -90
            scale = 0.9
            opacity = 0
        }
    }
}
