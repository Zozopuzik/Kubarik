//
//  Particle.swift
//  Kubarik
//
//  One particle = a small colored tile that flies out radially from its
//  spawn point, spins, scales down and fades. A ParticleField holds many
//  of them; line clears spawn ~7 per cleared cell.
//

import SwiftUI

struct Particle: Identifiable, Equatable {
    let id = UUID()
    let origin: CGPoint
    let angleRadians: Double
    let distance: CGFloat
    let size: CGFloat
    let color: TileColor
    let rotationDegrees: Double
    let lifetime: TimeInterval

    var targetOffset: CGSize {
        CGSize(
            width: CGFloat(cos(angleRadians)) * distance,
            height: CGFloat(sin(angleRadians)) * distance
        )
    }

    /// Builds N particles radiating from `point` in the given color.
    /// Even angular distribution with a small random jitter, random
    /// distance/size/rotation/lifetime for organic feel.
    static func burst(at point: CGPoint, color: TileColor, count: Int = 7) -> [Particle] {
        (0..<count).map { i in
            let baseAngle = (Double(i) / Double(count)) * .pi * 2
            let angle = baseAngle + Double.random(in: -0.22...0.22)
            let dist = CGFloat.random(in: 40...110)
            let size = CGFloat.random(in: 6...14)
            let rot = Double.random(in: -360...360)
            let life = TimeInterval.random(in: 0.7...1.05)
            return Particle(
                origin: CGPoint(
                    x: point.x + .random(in: -4...4),
                    y: point.y + .random(in: -4...4)
                ),
                angleRadians: angle,
                distance: dist,
                size: size,
                color: color,
                rotationDegrees: rot,
                lifetime: life
            )
        }
    }
}

struct ParticleView: View {
    let particle: Particle

    @State private var animated = false

    var body: some View {
        RoundedRectangle(cornerRadius: particle.size * 0.25, style: .continuous)
            .fill(particle.color.top)
            .shadow(color: particle.color.edge, radius: 0, x: 0, y: 2)
            .frame(width: particle.size, height: particle.size)
            .scaleEffect(animated ? 0.3 : 1)
            .opacity(animated ? 0 : 1)
            .rotationEffect(.degrees(animated ? particle.rotationDegrees : 0))
            .offset(animated ? particle.targetOffset : .zero)
            .position(particle.origin)
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(.timingCurve(0.2, 0.7, 0.3, 1, duration: particle.lifetime)) {
                    animated = true
                }
            }
    }
}
