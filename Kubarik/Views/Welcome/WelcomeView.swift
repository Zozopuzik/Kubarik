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
    @State private var legalSheet: LegalDoc?
    @State private var appleError: String?

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
        .sheet(item: $legalSheet) { doc in
            LegalDocView(doc: doc)
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

            Spacer().frame(height: 12)

            legalLinks
                .opacity(animated ? 1 : 0)
                .animation(
                    .easeOut(duration: ctaDuration).delay(ctaStart + 0.22),
                    value: animated
                )

            Spacer().frame(height: 18)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Legal links

    private var legalLinks: some View {
        HStack(spacing: 14) {
            legalLink("Terms of Use", doc: .terms)

            Text("·")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(Palette.taglineBrown.opacity(0.5))

            legalLink("Privacy Policy", doc: .privacy)
        }
    }

    private func legalLink(_ label: String, doc: LegalDoc) -> some View {
        Button { legalSheet = doc } label: {
            Text(label)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.3)
                .textCase(.uppercase)
                .foregroundStyle(Palette.taglineBrown.opacity(0.65))
                .padding(.vertical, 6)
                .padding(.horizontal, 4)
        }
        .buttonStyle(.plain)
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

            AppleSignInButton(
                onSuccess: handleAppleSignIn,
                onFailure: { error in appleError = error.localizedDescription }
            )
            .frame(width: 232)

            if let appleError {
                Text(appleError)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(0.2)
                    .foregroundStyle(Color(hex: 0xB23A2E).opacity(0.85))
                    .frame(maxWidth: 240)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func handleAppleSignIn(idToken: String, nonce: String, suggestedName: String?) {
        appleError = nil
        Task {
            do {
                try await auth.completeAppleSignIn(
                    idToken: idToken,
                    nonce: nonce,
                    suggestedName: suggestedName
                )
            } catch {
                appleError = error.localizedDescription
            }
        }
    }
}

#Preview {
    WelcomeView()
        .environment(AuthManager())
        .environment(AudioPlayer())
}
