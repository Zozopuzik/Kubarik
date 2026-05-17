//
//  ContentView.swift
//  Kubarik


import SwiftUI

struct ContentView: View {
    @State private var path: [AppRoute] = []
    @State private var auth = AuthManager()
    @State private var audio = AudioPlayer()
    @State private var prefs = PreferencesStore()
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashView(onComplete: dismissSplash)
                    .transition(.opacity)
            } else {
                mainStack
                    .transition(.opacity)
            }
        }
        .environment(auth)
        .environment(audio)
        .environment(prefs)
        .task {
            await auth.bootstrap()
        }
        .onChange(of: prefs.music) { _, new in
            audio.isMusicEnabled = new
        }
        .onAppear {
            audio.isMusicEnabled = prefs.music
        }
        .onOpenURL { url in
            Task { await auth.handleAuthCallback(url) }
        }
    }

    private var mainStack: some View {
        NavigationStack(path: $path) {
            WelcomeView(
                onStart: { path.append(.game) },
                onOpenLeaderboard: { path.append(.leaderboard) },
                onOpenProfile: { path.append(.profile) },
                onOpenSettings: { path.append(.settings) }
            )
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .game:        GameView()
                case .leaderboard: LeaderboardView()
                case .profile:     ProfileView()
                case .settings:    SettingsView()
                }
            }
        }
    }

    private func dismissSplash() {
        withAnimation(.easeOut(duration: 0.35)) {
            showSplash = false
        }
    }
}

#Preview {
    ContentView()
}
