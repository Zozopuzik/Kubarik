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
    @Environment(\.openURL) private var openURL
    @Environment(AuthManager.self) private var auth
    @Environment(PreferencesStore.self) private var prefs

    private let issuesURL = URL(string: "https://github.com/Zozopuzik/Kubarik/issues/new")!
    @State private var tab: ProfileTab = .info
    @State private var showRenameSheet = false
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @State private var deleteError: String?

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
        .alert("Delete account?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                performDelete()
            }
        } message: {
            Text("This permanently removes your profile, every game you've played, and your sign-in. We can't undo it.")
        }
        .alert("Couldn't delete", isPresented: Binding(get: { deleteError != nil }, set: { if !$0 { deleteError = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteError ?? "")
        }
    }

    private func performDelete() {
        isDeleting = true
        Task {
            do {
                try await auth.deleteAccount()
                isDeleting = false
                dismiss()
            } catch {
                isDeleting = false
                deleteError = error.localizedDescription
            }
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
                VStack(spacing: 6) {
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
                            .padding(.vertical, 10)
                            .padding(.horizontal, 28)
                    }

                    Button(action: { showDeleteConfirm = true }) {
                        HStack(spacing: 6) {
                            if isDeleting {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(0.75)
                            }
                            Text(isDeleting ? "DELETING…" : "DELETE ACCOUNT")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .tracking(2.2)
                                .foregroundStyle(Color(hex: 0xB23A2E).opacity(0.85))
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 24)
                    }
                    .disabled(isDeleting)
                }
                .padding(.bottom, 18)
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

                PrefSection(label: "Help us") {
                    PrefLinkRow(
                        label: "Report a bug or idea",
                        systemImage: "exclamationmark.bubble.fill",
                        action: { openURL(issuesURL) }
                    )
                }

                Text("Opens GitHub Issues in Safari. No account needed to read — sign in there if you want to post.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.taglineBrown.opacity(0.75))
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }
}

enum ProfileTab { case info, prefs }
