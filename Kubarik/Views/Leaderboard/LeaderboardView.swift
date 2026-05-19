//
//  LeaderboardView.swift
//  Kubarik
//
//  Top players by best_score. Podium for the top 3, scrollable list for
//  ranks 4..N. The signed-in user's row gets a coral tint plus a YOU pill.
//

import SwiftUI

struct LeaderboardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var auth

    @State private var profiles: [UserProfile] = []
    @State private var isLoading = true
    @State private var error: String? = nil

    private var meID: UUID? { auth.state.profile?.id }

    var body: some View {
        ZStack(alignment: .topLeading) {
            CreamBackground()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if profiles.isEmpty {
                    emptyState
                } else {
                    Spacer().frame(height: 4)
                    podium
                    Spacer().frame(height: 6)
                    restList
                    Spacer(minLength: 0)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task { await load() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            IconButton(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
            }
            Spacer()
            Text("Top Players")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.textBrown)
            Spacer()
            Color.clear.frame(width: 52, height: 52)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "trophy")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Palette.textBrown.opacity(0.45))
            Text("No scores yet")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(Palette.textBrown.opacity(0.7))
            Text("Be the first to top the chart.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Palette.textBrown.opacity(0.5))
            Spacer()
        }
    }

    // MARK: - Podium (top 3)

    private var podium: some View {
        let top3 = Array(profiles.prefix(3))
        // Visual order: 2nd · 1st · 3rd
        let display: [(rank: Int, profile: UserProfile?)] = [
            (2, top3.indices.contains(1) ? top3[1] : nil),
            (1, top3.indices.contains(0) ? top3[0] : nil),
            (3, top3.indices.contains(2) ? top3[2] : nil),
        ]

        return HStack(alignment: .bottom, spacing: 8) {
            ForEach(display, id: \.rank) { item in
                if let profile = item.profile {
                    PodiumColumn(
                        profile: profile,
                        place: item.rank,
                        isMe: profile.id == meID
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    Color.clear.frame(maxWidth: .infinity, maxHeight: 1)
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 230)
    }

    // MARK: - Static list (ranks 4..10 + optional "you" row)

    private var restList: some View {
        // Always render ranks 4..10 (or however many we have past the podium,
        // up to 7 entries). After that, if the signed-in user is beyond rank
        // 10 we show a "···" separator and their row pinned at the bottom.
        let visible = Array(profiles.enumerated())
            .dropFirst(3)
            .prefix(4)

        let userIndex = profiles.firstIndex { $0.id == meID }
        let userBeyondVisible: (Int, UserProfile)? = {
            guard let idx = userIndex, idx >= 7 else { return nil }
            return (idx, profiles[idx])
        }()

        return VStack(spacing: 4) {
            ForEach(Array(visible), id: \.element.id) { index, profile in
                LeaderboardRow(
                    rank: index + 1,
                    profile: profile,
                    isMe: profile.id == meID
                )
            }

            if let (idx, profile) = userBeyondVisible {
                ellipsisDivider
                LeaderboardRow(
                    rank: idx + 1,
                    profile: profile,
                    isMe: true
                )
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.32))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Palette.textBrown.opacity(0.08), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
    }

    private var ellipsisDivider: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { _ in
                Circle()
                    .fill(Palette.taglineBrown.opacity(0.55))
                    .frame(width: 6, height: 6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    // MARK: - Loading

    private func load() async {
        do {
            profiles = try await auth.leaderboard()
            isLoading = false
        } catch {
            self.error = "\(error)"
            isLoading = false
        }
    }
}

// MARK: - PodiumColumn

private struct PodiumColumn: View {
    let profile: UserProfile
    let place: Int
    let isMe: Bool

    private var trimColor: Color {
        switch place {
        case 1: return Color(hex: 0xFFC560) // gold
        case 2: return Color(hex: 0xC8C8D0) // silver
        default: return Color(hex: 0xD88A66) // bronze
        }
    }

    private var avatarSize: CGFloat { 56 }

    private var blockHeight: CGFloat {
        switch place {
        case 1: return 64
        case 2: return 48
        default: return 36
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            Spacer(minLength: 0)

            TileView(
                color: tileColor(for: profile.displayName),
                size: avatarSize,
                radius: avatarSize * 0.28,
                depth: max(5, avatarSize * 0.13),
                rotation: -2
            ) {
                Text(avatarLetter(profile.displayName))
                    .font(.system(size: avatarSize * 0.55, weight: .heavy, design: .rounded))
            }

            Text(profile.displayName)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(isMe ? Color(hex: 0xA03520) : Palette.textBrown)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.horizontal, 4)
                .padding(.top, 6)

            Text("\(profile.bestScore)")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(Palette.textBrown)
                .monospacedDigit()
                .padding(.bottom, 10)

            // Podium block — flat, no shadows / no 3-D edge
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(trimColor)
                .frame(height: blockHeight)
                .overlay(
                    Text("\(place)")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.top, 6),
                    alignment: .top
                )
                .padding(.horizontal, 6)
        }
    }
}

// MARK: - LeaderboardRow

private struct LeaderboardRow: View {
    let rank: Int
    let profile: UserProfile
    let isMe: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(hex: 0x7E5638))
                .monospacedDigit()
                .frame(width: 32, alignment: .trailing)

            TileView(
                color: tileColor(for: profile.displayName),
                size: 38,
                radius: 10,
                depth: 5
            ) {
                Text(avatarLetter(profile.displayName))
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.displayName)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(isMe ? Color(hex: 0xA03520) : Palette.textBrown)
                    .lineLimit(1)
                    .truncationMode(.tail)

                if isMe {
                    Text("YOU")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .tracking(1.4)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(TileColor.coral.top)
                        )
                }
            }

            Spacer()

            Text("\(profile.bestScore)")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(Palette.textBrown)
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isMe ? Color(hex: 0xFF7864).opacity(0.18) : Color.clear)
        )
    }
}

// MARK: - Shared helpers

/// Deterministic tile color from display name — same letters → same color,
/// stable across launches (uses unicode scalar sum, not Swift's randomised
/// hashValue).
private func tileColor(for name: String) -> TileColor {
    let palette: [TileColor] = [.coral, .turquoise, .lavender, .mint, .amber, .pink, .cornflower]
    let sum = name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
    return palette[abs(sum) % palette.count]
}

private func avatarLetter(_ name: String) -> String {
    name.first.map { String($0).uppercased() } ?? "?"
}
