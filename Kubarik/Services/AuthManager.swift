//
//  AuthManager.swift
//  Kubarik
//
//  Single source of truth for sign-in state. The whole UI reads
//  `state` and reacts; only this class talks to the AuthBackend.
//
//  Today `backend = MockAuthBackend()`. When the Supabase SDK is added,
//  flip that line to `SupabaseAuthBackend()` and everything else just
//  works — the rest of the app uses the AuthState enum, not Supabase
//  types.
//

import Foundation
import Observation

@MainActor
@Observable
final class AuthManager {
    private(set) var state: AuthState = .loading
    /// Lifetime "total points" — sum of every game's score. Refreshed
    /// after each game over and on bootstrap. Local fallback while
    /// signed out.
    private(set) var totalScore: Int = 0
    private let backend: AuthBackend

    init(backend: AuthBackend = SupabaseAuthBackend()) {
        self.backend = backend
    }

    /// Called from the app entry point. Restores any persisted session
    /// and either lands us in `.signedIn` or `.guest`.
    func bootstrap() async {
        do {
            guard let session = try await backend.restoreSession() else {
                state = .guest
                return
            }
            try await loadProfile(for: session.userId, suggestedName: session.suggestedName)
        } catch {
            state = .guest
        }
    }

    /// Completes a Sign in with Apple. `idToken` and `nonce` come from
    /// ASAuthorizationAppleIDCredential. `suggestedName` may be present
    /// only on a brand-new sign-in for that user.
    func completeAppleSignIn(idToken: String, nonce: String, suggestedName: String?) async throws {
        let session = try await backend.signInWithApple(
            idToken: idToken,
            nonce: nonce,
            suggestedName: suggestedName
        )
        try await loadProfile(for: session.userId, suggestedName: session.suggestedName ?? suggestedName)
    }

    /// Creates a new account. Requires Supabase "Confirm email" to be OFF.
    func signUp(email: String, password: String) async throws {
        let result = try await backend.signUp(email: email, password: password)
        try await loadProfile(for: result.userId, suggestedName: result.suggestedName)
    }

    /// Signs in an existing user with email + password.
    func signIn(email: String, password: String) async throws {
        let result = try await backend.signIn(email: email, password: password)
        try await loadProfile(for: result.userId, suggestedName: result.suggestedName)
    }

    /// Asks Supabase to email a magic link (kept for future use).
    func requestMagicLink(email: String) async throws {
        try await backend.sendMagicLink(email: email)
    }

    /// Wire this up from `.onOpenURL` on the root view.
    func handleAuthCallback(_ url: URL) async {
        do {
            let session = try await backend.handleAuthCallback(url)
            try await loadProfile(for: session.userId, suggestedName: session.suggestedName)
        } catch {
            // Failed link — keep current state, user can retry.
        }
    }

    /// Generates a random `Player_NNNN` nickname for first-time sign-ins.
    /// Users can rename later from the Profile screen.
    static func generatedNickname() -> String {
        "Player_\(Int.random(in: 100...9999))"
    }

    /// Logs a finished game to the cloud, pushes best score if beaten,
    /// and refreshes the lifetime total. Idempotent — safe to call after
    /// every game-over.
    func recordGameOver(score: Int, linesCleared: Int) async {
        guard case .signedIn(let profile) = state else {
            // Guest mode — keep a running local total for the Profile
            // screen even if the user hasn't signed in yet.
            totalScore += score
            return
        }
        do {
            try await backend.logGame(userId: profile.id, score: score, linesCleared: linesCleared)

            if score > profile.bestScore {
                let updated = try await backend.updateProfile(
                    userId: profile.id,
                    displayName: nil,
                    bestScore: score,
                    totalGames: profile.totalGames + 1
                )
                state = .signedIn(profile: updated)
            } else {
                let updated = try await backend.updateProfile(
                    userId: profile.id,
                    displayName: nil,
                    bestScore: nil,
                    totalGames: profile.totalGames + 1
                )
                state = .signedIn(profile: updated)
            }
            totalScore = (try? await backend.totalScore(userId: profile.id)) ?? totalScore
        } catch {
            // best-effort; keep local state
        }
    }

    /// Refreshes the lifetime total — used by the Profile screen on
    /// appear. No-op for guest users (they already track it locally).
    func refreshTotalScore() async {
        guard case .signedIn(let profile) = state else { return }
        if let total = try? await backend.totalScore(userId: profile.id) {
            totalScore = total
        }
    }

    /// Renames the signed-in user. Updates the local state on success so
    /// the avatar letter + display name update immediately.
    func updateDisplayName(_ newName: String) async throws {
        guard case .signedIn(let profile) = state else { return }
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return }
        let updated = try await backend.updateProfile(
            userId: profile.id,
            displayName: trimmed,
            bestScore: nil,
            totalGames: nil
        )
        state = .signedIn(profile: updated)
    }

    /// Pulls top N profiles for the leaderboard screen.
    func leaderboard(limit: Int = 100) async throws -> [UserProfile] {
        try await backend.topProfiles(limit: limit)
    }

    func signOut() async {
        try? await backend.signOut()
        state = .guest
    }

    // MARK: - Internals

    private func loadProfile(for userId: UUID, suggestedName: String?) async throws {
        let profile: UserProfile
        if let existing = try await backend.fetchProfile(userId: userId) {
            profile = existing
        } else {
            let name = suggestedName?.trimmingCharacters(in: .whitespacesAndNewlines)
                .nilIfEmpty ?? Self.generatedNickname()
            profile = try await backend.createProfile(userId: userId, displayName: name)
        }
        state = .signedIn(profile: profile)
        totalScore = (try? await backend.totalScore(userId: userId)) ?? 0
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
