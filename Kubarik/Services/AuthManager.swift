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
    private let queue: GameRecordQueue

    init(backend: AuthBackend? = nil, queue: GameRecordQueue? = nil) {
        // Default parameters can't construct @MainActor types directly —
        // they're evaluated at the call site, which may not be isolated.
        // Build the real instances inside the init body (which IS on the
        // main actor) and fall back to those when callers don't inject.
        self.backend = backend ?? SupabaseAuthBackend()
        self.queue = queue ?? GameRecordQueue()
    }

    /// How many game sessions are currently waiting for a sync to
    /// Supabase. Surfaced in the UI as a "X games pending" hint.
    var pendingRecordCount: Int { queue.pending.count }

    /// Called from the app entry point. Restores any persisted session
    /// and either lands us in `.signedIn` or `.guest`.
    func bootstrap() async {
        do {
            guard let session = try await backend.restoreSession() else {
                state = .guest
                return
            }
            try await loadProfile(for: session.userId, suggestedName: session.suggestedName)
            await flushPendingRecords()
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
        await flushPendingRecords()
    }

    /// Creates a new account. Requires Supabase "Confirm email" to be OFF.
    func signUp(email: String, password: String) async throws {
        let result = try await backend.signUp(email: email, password: password)
        try await loadProfile(for: result.userId, suggestedName: result.suggestedName)
        await flushPendingRecords()
    }

    /// Signs in an existing user with email + password.
    func signIn(email: String, password: String) async throws {
        let result = try await backend.signIn(email: email, password: password)
        try await loadProfile(for: result.userId, suggestedName: result.suggestedName)
        await flushPendingRecords()
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
        let pending = PendingGameRecord(
            id: UUID(),
            score: score,
            linesCleared: linesCleared,
            playedAt: Date()
        )

        guard case .signedIn(let profile) = state else {
            // Guest mode — queue the record for a future sign-in flush
            // and keep the running local total in sync.
            queue.enqueue(pending)
            totalScore += score
            return
        }

        do {
            try await backend.logGame(userId: profile.id, score: score, linesCleared: linesCleared)

            let updated = try await backend.updateProfile(
                userId: profile.id,
                displayName: nil,
                bestScore: score > profile.bestScore ? score : nil,
                totalGames: profile.totalGames + 1
            )
            state = .signedIn(profile: updated)
            totalScore = (try? await backend.totalScore(userId: profile.id)) ?? totalScore
        } catch {
            // Network blip mid game-over — park the record so the next
            // flush picks it up. Local totalScore still climbs so the UI
            // doesn't lie about the just-finished game.
            queue.enqueue(pending)
            totalScore += score
        }
    }

    /// Drains the pending-game queue into Supabase. Called after
    /// successful sign-in and on bootstrap when a session is restored.
    /// Silently bails on the first network failure so the next attempt
    /// retries the remainder.
    func flushPendingRecords() async {
        guard case .signedIn(let profile) = state, !queue.pending.isEmpty else { return }

        var maxScoreInBatch = 0
        var flushedCount = 0

        for record in queue.pending {
            do {
                try await backend.logGame(
                    userId: profile.id,
                    score: record.score,
                    linesCleared: record.linesCleared
                )
                queue.remove(id: record.id)
                maxScoreInBatch = max(maxScoreInBatch, record.score)
                flushedCount += 1
            } catch {
                return
            }
        }

        guard flushedCount > 0 else { return }

        let newBestNeeded = maxScoreInBatch > profile.bestScore
        do {
            let updated = try await backend.updateProfile(
                userId: profile.id,
                displayName: nil,
                bestScore: newBestNeeded ? maxScoreInBatch : nil,
                totalGames: profile.totalGames + flushedCount
            )
            state = .signedIn(profile: updated)
        } catch {
            // Stats refresh failed — records are already persisted in
            // games table, that's the source of truth. Next launch will
            // recompute via totalScore RPC.
        }
        totalScore = (try? await backend.totalScore(userId: profile.id)) ?? totalScore
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
        totalScore = 0
    }

    /// Permanently deletes the signed-in user — auth row, profile, every
    /// game record. Returns the user to guest state on success. Required
    /// by App Store Review guideline 5.1.1(v).
    func deleteAccount() async throws {
        guard case .signedIn(let profile) = state else { return }
        try await backend.deleteAccount(userId: profile.id)
        state = .guest
        totalScore = 0
        // Drop any unsynced records so they don't leak into the next
        // sign-in (which will likely be a different account anyway).
        queue.clear()
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
