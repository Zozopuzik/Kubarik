//
//  HapticEngine.swift
//  Kubarik
//
//  Bigger, chunkier haptics than `.sensoryFeedback` can deliver on its
//  own. Drives UIKit's UIImpactFeedbackGenerator + UINotificationFeedback
//  directly and fires *sequences* of pulses for big events (line clears,
//  full clears, game over) — felt as a single thick "boom" rather than
//  a thin tap.
//
//  Owned as @State in GameView so generators live for the full game
//  session; we `prepare()` them eagerly so the first hit lands without
//  the usual ~200ms warm-up latency.
//

import UIKit

@MainActor
final class HapticEngine {
    /// Set by GameView from the user preference. `off` short-circuits
    /// every `play(...)` call; `high` adds an extra rigid kick and a
    /// fuller chain on big events.
    var level: HapticLevel = .medium

    private let lightGen = UIImpactFeedbackGenerator(style: .light)
    private let mediumGen = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGen = UIImpactFeedbackGenerator(style: .heavy)
    private let rigidGen = UIImpactFeedbackGenerator(style: .rigid)
    private let notifGen = UINotificationFeedbackGenerator()

    init() {
        prepareAll()
    }

    func prepareAll() {
        lightGen.prepare()
        mediumGen.prepare()
        heavyGen.prepare()
        rigidGen.prepare()
        notifGen.prepare()
    }

    func play(_ pulse: HapticPulse) {
        guard level != .off else { return }
        Task { @MainActor in
            await dispatch(pulse.kind)
            prepareAll() // keep them warm for the next event
        }
    }

    private func dispatch(_ kind: HapticPulse.Kind) async {
        let isHigh = level == .high
        switch kind {
        case .pickup:
            heavyGen.impactOccurred(intensity: isHigh ? 1.0 : 0.85)
            if isHigh {
                try? await Task.sleep(for: .milliseconds(25))
                rigidGen.impactOccurred(intensity: 0.85)
            }

        case .placement(let cells):
            heavyGen.impactOccurred(intensity: 1.0)
            // High always echoes; medium echoes only for bigger pieces.
            if isHigh || cells >= 4 {
                try? await Task.sleep(for: .milliseconds(35))
                rigidGen.impactOccurred(intensity: isHigh ? 1.0 : 0.85)
            }
            if isHigh {
                try? await Task.sleep(for: .milliseconds(35))
                heavyGen.impactOccurred(intensity: 0.9)
            }

        case .linesCleared(let n):
            heavyGen.impactOccurred(intensity: 1.0)
            try? await Task.sleep(for: .milliseconds(45))
            notifGen.notificationOccurred(.success)

            // Always do n-1 follow-up heavies for n>=2.
            let follows = max(0, n - 1)
            for _ in 0..<follows {
                try? await Task.sleep(for: .milliseconds(isHigh ? 70 : 85))
                heavyGen.impactOccurred(intensity: 1.0)
            }
            // High mode: a final rigid kick to close out the chain.
            if isHigh {
                try? await Task.sleep(for: .milliseconds(80))
                rigidGen.impactOccurred(intensity: 1.0)
                try? await Task.sleep(for: .milliseconds(60))
                notifGen.notificationOccurred(.success)
            }

        case .fullClear:
            heavyGen.impactOccurred(intensity: 1.0)
            try? await Task.sleep(for: .milliseconds(50))
            notifGen.notificationOccurred(.success)
            try? await Task.sleep(for: .milliseconds(160))
            heavyGen.impactOccurred(intensity: 1.0)
            try? await Task.sleep(for: .milliseconds(90))
            notifGen.notificationOccurred(.success)
            if isHigh {
                try? await Task.sleep(for: .milliseconds(140))
                rigidGen.impactOccurred(intensity: 1.0)
                try? await Task.sleep(for: .milliseconds(90))
                rigidGen.impactOccurred(intensity: 1.0)
            }

        case .gameOver:
            notifGen.notificationOccurred(.error)
            try? await Task.sleep(for: .milliseconds(140))
            heavyGen.impactOccurred(intensity: 1.0)
            try? await Task.sleep(for: .milliseconds(130))
            heavyGen.impactOccurred(intensity: 1.0)
            if isHigh {
                try? await Task.sleep(for: .milliseconds(130))
                rigidGen.impactOccurred(intensity: 1.0)
            }
        }
    }
}
