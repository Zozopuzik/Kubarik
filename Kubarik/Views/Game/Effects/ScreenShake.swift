//
//  ScreenShake.swift
//  Kubarik
//
//  Tiny driver for shaking the game view on line clears. Each call to
//  `trigger(intensity:)` plays a short multi-step wobble whose amplitude
//  scales with the intensity (lines cleared + combo modifier).
//

import SwiftUI

@Observable
final class ScreenShakeDriver {
    private(set) var offset: CGSize = .zero
    private(set) var rotation: Double = 0
    private var pulseTask: Task<Void, Never>? = nil

    func trigger(intensity: Int) {
        pulseTask?.cancel()
        let amp = CGFloat(min(max(intensity, 1), 4))

        pulseTask = Task { @MainActor in
            // 6-step wobble — mirrors the CSS keyframes from the design.
            let steps: [(dx: CGFloat, dy: CGFloat, rot: Double)] = [
                (-3 * amp, -1 * amp, -0.4 * Double(amp)),
                ( 3 * amp,  1 * amp,  0.4 * Double(amp)),
                (-2 * amp,  1 * amp,  0),
                ( 2 * amp, -1 * amp,  0),
                (-1 * amp,  0,        0),
                ( 1 * amp,  0,        0),
            ]
            for step in steps {
                try? await Task.sleep(for: .milliseconds(50))
                withAnimation(.easeOut(duration: 0.05)) {
                    offset = CGSize(width: step.dx, height: step.dy)
                    rotation = step.rot
                }
            }
            try? await Task.sleep(for: .milliseconds(60))
            withAnimation(.spring(response: 0.20, dampingFraction: 0.65)) {
                offset = .zero
                rotation = 0
            }
        }
    }
}

extension View {
    func screenShake(_ driver: ScreenShakeDriver) -> some View {
        self
            .offset(driver.offset)
            .rotationEffect(.degrees(driver.rotation))
    }
}
