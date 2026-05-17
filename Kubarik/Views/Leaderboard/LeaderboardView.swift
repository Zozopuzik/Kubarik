//
//  LeaderboardView.swift
//  Kubarik
//
//  Top-100 by best_score. Pulls from AuthManager.leaderboard() so the
//  backend swap (mock → Supabase) is invisible here.
//

import SwiftUI

struct LeaderboardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var auth

    @State private var profiles: [UserProfile] = []
    @State private var isLoading = true
    @State private var error: String? = nil

    var body: some View {
        ZStack(alignment: .topLeading) {
            CreamBackground()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                Spacer().frame(height: 18)

                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if profiles.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task { await load() }
    }

    private var header: some View {
        HStack(alignment: .center) {
            IconButton(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .bold))
            }
            Spacer()
            Text("LEADERBOARD")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .tracking(2.5)
                .foregroundStyle(Palette.taglineBrown)
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

    private var list: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(Array(profiles.enumerated()), id: \.element.id) { index, profile in
                    row(rank: index + 1, profile: profile)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private func row(rank: Int, profile: UserProfile) -> some View {
        let isMe = auth.state.profile?.id == profile.id
        return HStack {
            Text("#\(rank)")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(rankColor(rank))
                .frame(width: 44, alignment: .leading)

            Text(profile.displayName)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.textBrown)

            Spacer()

            Text("\(profile.bestScore)")
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(Palette.textBrown)
                .monospacedDigit()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isMe ? Color(hex: 0xFFC560).opacity(0.25) : Color.white.opacity(0.45))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(isMe ? Color(hex: 0xE0993B).opacity(0.55) : Palette.textBrown.opacity(0.10), lineWidth: 1)
        )
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return Color(hex: 0xE0993B)
        case 2: return Color(hex: 0x8C643C)
        case 3: return Color(hex: 0xC07A4A)
        default: return Palette.textBrown.opacity(0.55)
        }
    }

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
