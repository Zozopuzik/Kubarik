//
//  SupabaseAuthBackend.swift
//  Kubarik
//
//  Real-Supabase implementation of AuthBackend. Talks to the project
//  configured in SupabaseConfig. Same surface as MockAuthBackend so the
//  rest of the app doesn't care which one is wired in.
//
//  Requires the `supabase-swift` SPM dependency with at least the Auth
//  and PostgREST products added to the Kubarik target.
//

import Foundation
import Supabase

final class SupabaseAuthBackend: AuthBackend {
    private let client: SupabaseClient

    init() {
        self.client = SupabaseClient(
            supabaseURL: SupabaseConfig.projectURL,
            supabaseKey: SupabaseConfig.anonKey
        )
    }

    // MARK: - Session

    func restoreSession() async throws -> SignInResult? {
        do {
            let session = try await client.auth.session
            return SignInResult(userId: session.user.id, suggestedName: nil)
        } catch {
            // No session persisted yet — that's fine, treat as guest.
            return nil
        }
    }

    func signInWithApple(idToken: String, nonce: String, suggestedName: String?) async throws -> SignInResult {
        let session = try await client.auth.signInWithIdToken(
            credentials: OpenIDConnectCredentials(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )
        return SignInResult(userId: session.user.id, suggestedName: suggestedName)
    }

    func signUp(email: String, password: String) async throws -> SignInResult {
        let response = try await client.auth.signUp(email: email, password: password)
        // With "Confirm email" disabled Supabase returns a usable session
        // straight away; otherwise we have no session yet.
        if let session = response.session {
            return SignInResult(userId: session.user.id, suggestedName: nil)
        }
        // Fall back to the user id from the unconfirmed account so the
        // caller can surface a "check your email" error message.
        throw NSError(
            domain: "Kubarik.Auth",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Email confirmation required. Turn off 'Confirm email' in Supabase Auth settings."]
        )
    }

    func signIn(email: String, password: String) async throws -> SignInResult {
        let session = try await client.auth.signIn(email: email, password: password)
        return SignInResult(userId: session.user.id, suggestedName: nil)
    }

    func sendMagicLink(email: String) async throws {
        try await client.auth.signInWithOTP(
            email: email,
            redirectTo: URL(string: "kubarik://login-callback")
        )
    }

    func handleAuthCallback(_ url: URL) async throws -> SignInResult {
        let session = try await client.auth.session(from: url)
        return SignInResult(userId: session.user.id, suggestedName: nil)
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    // MARK: - Profiles

    func fetchProfile(userId: UUID) async throws -> UserProfile? {
        do {
            let profile: UserProfile = try await client
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            return profile
        } catch {
            // PGRST116 = "no rows" on .single(); treat as "profile not yet
            // created" rather than a hard failure.
            if isNoRowsError(error) { return nil }
            throw error
        }
    }

    func createProfile(userId: UUID, displayName: String) async throws -> UserProfile {
        let payload = NewProfile(id: userId, displayName: displayName)
        let profile: UserProfile = try await client
            .from("profiles")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
        return profile
    }

    func updateProfile(userId: UUID, displayName: String?, bestScore: Int?, totalGames: Int?) async throws -> UserProfile {
        let payload = ProfileUpdate(
            displayName: displayName,
            bestScore: bestScore,
            totalGames: totalGames
        )
        let profile: UserProfile = try await client
            .from("profiles")
            .update(payload)
            .eq("id", value: userId.uuidString)
            .select()
            .single()
            .execute()
            .value
        return profile
    }

    // MARK: - Games

    func logGame(userId: UUID, score: Int, linesCleared: Int) async throws {
        let payload = NewGameRecord(
            userId: userId,
            score: score,
            linesCleared: linesCleared
        )
        try await client
            .from("games")
            .insert(payload)
            .execute()
    }

    func totalScore(userId: UUID) async throws -> Int {
        // Use the Postgres function we defined alongside the table; one
        // round-trip, server-side aggregation.
        let response: Int = try await client
            .rpc("get_user_total_score", params: ["p_user_id": userId.uuidString])
            .execute()
            .value
        return response
    }

    func topProfiles(limit: Int) async throws -> [UserProfile] {
        let profiles: [UserProfile] = try await client
            .from("profiles")
            .select()
            .order("best_score", ascending: false)
            .limit(limit)
            .execute()
            .value
        return profiles
    }

    // MARK: - Helpers

    /// PostgREST returns code "PGRST116" when `.single()` finds zero rows.
    /// Easiest way to detect it without depending on private error types
    /// is to look at the localized description.
    private func isNoRowsError(_ error: Error) -> Bool {
        let s = String(describing: error)
        return s.contains("PGRST116") || s.lowercased().contains("no rows")
    }
}

// MARK: - Encodable payloads

private struct NewProfile: Encodable {
    let id: UUID
    let displayName: String

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
    }
}

private struct ProfileUpdate: Encodable {
    let displayName: String?
    let bestScore: Int?
    let totalGames: Int?

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case bestScore = "best_score"
        case totalGames = "total_games"
    }
}
