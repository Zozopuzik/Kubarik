//
//  AuthBackend.swift
//  Kubarik
//
//  The protocol AuthManager talks to. Today it's backed by an in-process
//  mock (UserDefaults persistence) so the UI flow works end-to-end
//  without Supabase. When the SDK is added, a SupabaseAuthBackend class
//  conforming to this protocol replaces the mock in one line in
//  AuthManager — nothing else in the codebase changes.
//

import Foundation

protocol AuthBackend: AnyObject {
    /// Returns the currently-restored session, if any. Called on app
    /// launch to decide whether the user is already signed in.
    func restoreSession() async throws -> SignInResult?

    /// Trades an Apple identity token (and nonce) for a Supabase session.
    /// On success returns the user id plus whatever Apple gave us for
    /// display-name suggestion. The profile row may not exist yet.
    /// Used when paid Apple Developer Program is available; otherwise we
    /// fall back to `sendMagicLink`.
    func signInWithApple(idToken: String, nonce: String, suggestedName: String?) async throws -> SignInResult

    /// Creates a new account with email + password. Requires Supabase
    /// "Confirm email" to be OFF so the session is returned immediately.
    func signUp(email: String, password: String) async throws -> SignInResult

    /// Signs in an existing user with email + password.
    func signIn(email: String, password: String) async throws -> SignInResult

    /// Magic-link API (kept for future use — UI no longer surfaces it).
    func sendMagicLink(email: String) async throws

    /// Called from `.onOpenURL` when the user comes back from tapping the
    /// magic link. Resolves the URL into a SignInResult.
    func handleAuthCallback(_ url: URL) async throws -> SignInResult

    /// Fetches the user's profile row, or nil if it doesn't exist yet
    /// (i.e. brand-new user who hasn't picked a nickname).
    func fetchProfile(userId: UUID) async throws -> UserProfile?

    /// Creates a fresh profile row for a brand-new user.
    func createProfile(userId: UUID, displayName: String) async throws -> UserProfile

    /// Updates fields on an existing profile.
    func updateProfile(userId: UUID, displayName: String?, bestScore: Int?, totalGames: Int?) async throws -> UserProfile

    /// Top N profiles by best_score. For the leaderboard screen.
    func topProfiles(limit: Int) async throws -> [UserProfile]

    /// Drops the session and clears any cached identity.
    func signOut() async throws

    /// Deletes the signed-in user's profile, game history, and auth record.
    /// Hard requirement for App Store review when the app offers account
    /// creation. Implemented server-side so the caller doesn't need
    /// service_role permissions.
    func deleteAccount(userId: UUID) async throws

    // MARK: - Game history

    /// Persists a finished game session. The lifetime "total points"
    /// stat on the Profile screen is the sum of `score` across rows.
    func logGame(userId: UUID, score: Int, linesCleared: Int) async throws

    /// Sum of `score` across all games for this user.
    func totalScore(userId: UUID) async throws -> Int
}

struct SignInResult: Equatable {
    let userId: UUID
    /// Whatever Apple disclosed at sign-in. Only present on the very
    /// first sign-in for that user — Apple does not resend it.
    let suggestedName: String?
}
