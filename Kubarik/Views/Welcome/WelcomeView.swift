//
//  WelcomeView.swift
//  Kubarik
//
//  The first screen the user sees. Letter-tile logo (KUBARIKI), tagline,
//  Play CTA, and a row of utility icons. On appear, an entrance
//  choreography plays: cubes fly in from edges, letters drop one by one
//  with a small overshoot, then the tagline and CTA fade in.
//

import SwiftUI

struct WelcomeView: View {
    var onStart: () -> Void = {}
    var onOpenLeaderboard: () -> Void = {}
    var onOpenProfile: () -> Void = {}
    var onOpenSettings: () -> Void = {}

    @Environment(AuthManager.self) private var auth
    @Environment(AudioPlayer.self) private var audio
    @State private var animated = false
    @State private var showSignIn = false

    // Timing knobs (seconds). One central place so the sequence is easy to retune.
    private let cubeStart: Double      = 0
    private let cubeStagger: Double    = 0.06
    private let cubeDuration: Double   = 0.52

    private let lettersStart: Double   = 0.52
    private let letterStagger: Double  = 0.07

    private let taglineStart: Double   = 0.52 + 8 * 0.07 + 0.12   // ~1.20
    private let taglineDuration: Double = 0.38

    private let ctaStart: Double       = 0.52 + 8 * 0.07 + 0.12 + 0.38 // ~1.58
    private let ctaDuration: Double    = 0.40

    var body: some View {
        ZStack(alignment: .topLeading) {
            CreamBackground()
            decorativeCubes
            mainContent
        }
        .onAppear {
            animated = true
            audio.playBackgroundLoop("Pineapple Pause")
        }
        .sheet(isPresented: $showSignIn) {
            EmailSignInSheet()
        }
    }

    // MARK: - Decorative cubes

    private var decorativeCubes: some View {
        ZStack(alignment: .topLeading) {
            Color.clear

            ForEach(Array(WelcomeData.cubes.enumerated()), id: \.element.id) { index, cube in
                TileView(
                    color: cube.color,
                    size: cube.size,
                    rotation: cube.rotation,
                    cast: true
                )
                .opacity(cube.opacity)
                .position(x: cube.x + cube.size / 2, y: cube.y + cube.size / 2)
                .offset(animated ? .zero : cube.from.offset)
                .opacity(animated ? 1 : 0)
                .animation(
                    .easeOut(duration: cubeDuration)
                        .delay(cubeStart + Double(index) * cubeStagger),
                    value: animated
                )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Main content

    private var mainContent: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 96)

            logoLetters

            Spacer().frame(height: 26)

            tagline

            Spacer(minLength: 0)

            playButton

            Spacer().frame(height: 30)

            iconRow

            Spacer().frame(height: 14)

            SDSMark()
                .opacity(animated ? 1 : 0)
                .offset(y: animated ? 0 : 10)
                .animation(
                    .easeOut(duration: ctaDuration).delay(ctaStart + 0.12),
                    value: animated
                )

            Spacer().frame(height: 30)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Logo letters

    private var logoLetters: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                ForEach(Array(WelcomeData.letters.prefix(4).enumerated()), id: \.element.id) { index, letter in
                    letterTile(letter, index: index)
                }
            }
            HStack(spacing: 10) {
                ForEach(Array(WelcomeData.letters.suffix(4).enumerated()), id: \.element.id) { index, letter in
                    letterTile(letter, index: index + 4)
                }
            }
        }
    }

    private func letterTile(_ letter: WelcomeLetter, index: Int) -> some View {
        TileView(
            color: letter.color,
            size: 64,
            radius: 18,
            depth: 8,
            rotation: letter.rotation
        ) {
            Text(letter.character)
                .font(.system(size: 40, weight: .bold, design: .rounded))
        }
        .opacity(animated ? 1 : 0)
        .offset(y: animated ? 0 : -260)
        .animation(
            .spring(response: 0.54, dampingFraction: 0.62)
                .delay(lettersStart + Double(index) * letterStagger),
            value: animated
        )
    }

    // MARK: - Tagline

    private var tagline: some View {
        Text("DROP · POP · CHILL")
            .font(.system(size: 16, weight: .heavy, design: .rounded))
            .tracking(3.2)
            .foregroundStyle(Palette.taglineBrown)
            .opacity(animated ? 1 : 0)
            .offset(y: animated ? 0 : 10)
            .animation(
                .easeOut(duration: taglineDuration).delay(taglineStart),
                value: animated
            )
    }

    // MARK: - Play CTA

    private var playButton: some View {
        PlayButton(
            pulseAfter: ctaStart + ctaDuration + 0.3,
            action: onStart
        )
        .opacity(animated ? 1 : 0)
        .offset(y: animated ? 0 : 10)
        .animation(
            .easeOut(duration: ctaDuration).delay(ctaStart),
            value: animated
        )
    }

    // MARK: - Auth-aware bottom row

    @ViewBuilder
    private var iconRow: some View {
        Group {
            switch auth.state {
            case .signedIn:
                signedInIcons
            case .needsNickname, .loading:
                Color.clear.frame(height: 52)
            case .guest:
                signInCta
            }
        }
        .opacity(animated ? 1 : 0)
        .offset(y: animated ? 0 : 10)
        .animation(
            .easeOut(duration: ctaDuration).delay(ctaStart + 0.12),
            value: animated
        )
    }

    private var signedInIcons: some View {
        HStack(spacing: 18) {
            IconButton(action: onOpenLeaderboard) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 22, weight: .semibold))
            }
            IconButton(action: onOpenProfile) {
                Image(systemName: "person.fill")
                    .font(.system(size: 22, weight: .semibold))
            }
        }
    }

    private var signInCta: some View {
        VStack(spacing: 10) {
            Text("Want to compete?")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .tracking(1.6)
                .textCase(.uppercase)
                .foregroundStyle(Palette.taglineBrown.opacity(0.85))

            Button {
                showSignIn = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Sign in with email")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .tracking(0.5)
                }
                .foregroundStyle(.white)
                .padding(.vertical, 14)
                .padding(.horizontal, 26)
                .frame(width: 232)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(hex: 0x3A2A1E))
                )
                .shadow(color: .black.opacity(0.20), radius: 14, x: 0, y: 8)
            }
        }
    }
}

#Preview {
    WelcomeView()
        .environment(AuthManager())
        .environment(AudioPlayer())
}
