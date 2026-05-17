//
//  AudioPlayer.swift
//  Kubarik
//
//  Tiny wrapper over AVAudioPlayer for game music. Plays one looping
//  background track at a time but does *crossfades* between tracks —
//  the outgoing one keeps playing while it fades out and the incoming
//  one fades in simultaneously, so transitions never feel like a cut.
//
//  Uses `.ambient` audio session — our music gracefully yields to the
//  user's Spotify / Apple Music if they're listening already.
//

import AVFoundation
import Observation

@MainActor
@Observable
final class AudioPlayer {
    private var current: AVAudioPlayer?
    private var fadingOut: AVAudioPlayer?
    private(set) var currentTrackName: String? = nil

    /// Target volume for music when it's on. Game music should sit
    /// well below SFX/haptics — 0.28 is comfortably quiet.
    private let backgroundVolume: Float = 0.28

    /// How long it takes for a brand-new track to climb to full volume,
    /// and for the outgoing track to fade to zero, when crossfading.
    private let crossfadeIn: TimeInterval = 1.6
    private let crossfadeOut: TimeInterval = 1.4

    var isMusicEnabled: Bool = true {
        didSet {
            guard let player = current else { return }
            if isMusicEnabled {
                if !player.isPlaying { player.play() }
                player.setVolume(backgroundVolume, fadeDuration: 0.5)
            } else {
                player.setVolume(0, fadeDuration: 0.4)
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(420))
                    if !self.isMusicEnabled { player.pause() }
                }
            }
        }
    }

    init() {
        configureSession()
    }

    private func configureSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Best-effort.
        }
    }

    // MARK: - Background music

    /// Crossfades to the named track. If the same track is already
    /// playing, this is a no-op.
    func playBackgroundLoop(_ name: String, ext: String = "mp3") {
        guard currentTrackName != name else { return }

        // Demote whatever is playing now to the "fading out" slot.
        if let outgoing = current {
            outgoing.setVolume(0, fadeDuration: crossfadeOut)
            fadingOut = outgoing
            // Stop the previous fading-out track if it didn't finish yet,
            // to keep memory + active player count in check.
            scheduleStop(outgoing, after: crossfadeOut + 0.1)
        }

        // Load the new one.
        guard let url = Bundle.main.url(forResource: name, withExtension: ext),
              let player = try? AVAudioPlayer(contentsOf: url) else {
            current = nil
            currentTrackName = nil
            return
        }

        player.numberOfLoops = -1
        player.volume = 0
        current = player
        currentTrackName = name

        guard isMusicEnabled else { return }
        player.play()
        player.setVolume(backgroundVolume, fadeDuration: crossfadeIn)
    }

    /// Fade-out + stop. No-op if nothing is playing.
    func stopBackgroundLoop(fadeOut: TimeInterval = 0.8) {
        guard let player = current else { return }
        currentTrackName = nil
        current = nil

        player.setVolume(0, fadeDuration: fadeOut)
        scheduleStop(player, after: fadeOut + 0.1)
    }

    private func scheduleStop(_ player: AVAudioPlayer, after delay: TimeInterval) {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            player.stop()
            if self.fadingOut === player { self.fadingOut = nil }
        }
    }
}
