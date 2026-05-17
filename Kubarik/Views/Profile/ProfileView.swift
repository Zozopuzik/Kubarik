//
//  ProfileView.swift
//  Kubarik
//
//  Two-tab screen — INFO (identity + stats) and PREFERENCES (settings).
//  Mirrors the design's pill tab-switcher with sliding dark thumb.
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var auth
    @Environment(PreferencesStore.self) private var prefs
    @State private var tab: ProfileTab = .info
    @State private var showRenameSheet = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            CreamBackground()

            VStack(spacing: 0) {
                header
                Spacer().frame(height: 12)
                tabSwitcher
                    .padding(.horizontal, 16)

                Spacer().frame(height: 22)

                Group {
                    switch tab {
                    case .info: infoTab
                    case .prefs: prefsTab
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await auth.refreshTotalScore()
        }
        .sheet(isPresented: $showRenameSheet) {
            NicknameEditSheet(
                currentName: auth.state.profile?.displayName ?? "Player",
                onSubmit: { newName in
                    try await auth.updateDisplayName(newName)
                }
            )
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            IconButton(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
            }
            Spacer()
            Text("Profile")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.textBrown)
            Spacer()
            Color.clear.frame(width: 52, height: 52)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // MARK: - Tab switcher

    private var tabSwitcher: some View {
        let activeIndex: Int = (tab == .info) ? 0 : 1
        return GeometryReader { proxy in
            let inset: CGFloat = 4
            let thumbWidth = (proxy.size.width - inset * 2) / 2

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.55))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Palette.textBrown.opacity(0.12), lineWidth: 1)
                    )

                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(hex: 0x6B3F22))
                    .shadow(color: Color(hex: 0x4A2A14), radius: 0, x: 0, y: 3)
                    .frame(width: thumbWidth, height: proxy.size.height - inset * 2)
                    .offset(x: inset + CGFloat(activeIndex) * thumbWidth, y: inset)
                    .animation(.spring(response: 0.28, dampingFraction: 0.75), value: tab)

                HStack(spacing: 0) {
                    tabButton(.info, label: "INFO")
                    tabButton(.prefs, label: "PREFERENCES")
                }
            }
        }
        .frame(height: 46)
    }

    private func tabButton(_ target: ProfileTab, label: String) -> some View {
        Button(action: { tab = target }) {
            Text(label)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .tracking(1.6)
                .foregroundStyle(tab == target ? Color(hex: 0xFFF8EE) : Palette.taglineBrown)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .animation(.easeInOut(duration: 0.18), value: tab)
    }

    // MARK: - Info tab

    private var infoTab: some View {
        let profile = auth.state.profile

        return VStack(spacing: 18) {
            avatarCube(for: profile)

            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Text(profile?.displayName ?? "Player")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(Palette.textBrown)

                    if profile != nil {
                        Button(action: { showRenameSheet = true }) {
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundStyle(Palette.textBrown.opacity(0.7))
                                .frame(width: 28, height: 28)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.55))
                                        .overlay(
                                            Circle()
                                                .strokeBorder(Palette.textBrown.opacity(0.18), lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let createdAt = profile?.createdAt {
                    Text("JOINED · \(createdAt.formatted(.dateTime.month(.abbreviated).year()).uppercased())")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(1.6)
                        .foregroundStyle(Palette.taglineBrown)
                }
            }

            statsGrid(
                best: profile?.bestScore ?? 0,
                games: profile?.totalGames ?? 0,
                total: auth.totalScore
            )
            .padding(.horizontal, 16)
            .padding(.top, 4)

            Spacer()

            if profile != nil {
                Button(action: {
                    Task {
                        await auth.signOut()
                        dismiss()
                    }
                }) {
                    Text("SIGN OUT")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .tracking(2.4)
                        .foregroundStyle(Palette.textBrown.opacity(0.65))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 28)
                }
                .padding(.bottom, 22)
            }
        }
    }

    private func avatarCube(for profile: UserProfile?) -> some View {
        let letter = profile?.displayName.prefix(1).uppercased() ?? "K"
        return TileView(
            color: .coral,
            size: 110,
            radius: 32,
            depth: 14,
            rotation: -4
        ) {
            Text(letter)
                .font(.system(size: 70, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: TileColor.coral.edge, radius: 0, x: 0, y: 2)
                .shadow(color: TileColor.coral.edge, radius: 0, x: 0, y: 4)
                .shadow(color: .black.opacity(0.22), radius: 12, x: 0, y: 8)
        }
    }

    private func statsGrid(best: Int, games: Int, total: Int) -> some View {
        let lines = max(0, best / 8)

        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            StatCard(label: "BEST",  value: "\(best)",  color: .amber,    iconName: "trophy.fill")
            StatCard(label: "TOTAL", value: "\(total)", color: .lavender, iconName: "sum")
            StatCard(label: "GAMES", value: "\(games)", color: .coral,    iconName: "gamecontroller.fill")
            StatCard(label: "LINES", value: "\(lines)", color: .mint,     iconName: "line.3.horizontal")
        }
    }

    // MARK: - Prefs tab

    private var prefsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PrefSection(label: "Audio & feel") {
                    PrefRow(label: "Music", divider: true) {
                        ToggleSwitch(isOn: Binding(get: { prefs.music }, set: { prefs.music = $0 }))
                    }
                    PrefRow(label: "Haptics") {
                        HapticLevelPicker(value: Binding(
                            get: { prefs.hapticLevel },
                            set: { prefs.hapticLevel = $0 }
                        ))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }
}

enum ProfileTab { case info, prefs }
