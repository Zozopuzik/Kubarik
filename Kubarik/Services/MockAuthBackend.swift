//
//  MockAuthBackend.swift
//  Kubarik
//
//  In-process backend that fakes Supabase using UserDefaults. Lets us
//  build and test the full sign-in / nickname / score-sync flow before
//  the real SDK is wired up. Will be swapped out for SupabaseAuthBackend
//  once `supabase-swift` is added through SPM.
//

import Foundation

final class MockAuthBackend: AuthBackend {
    private let defaults = UserDefaults.standard
    private let sessionKey = "kubarik.mock.sessionUserId"
    private let profilesKey = "kubarik.mock.profilesByUserId"

    func restoreSession() async throws -> SignInResult? {
        guard let raw = defaults.string(forKey: sessionKey),
              let userId = UUID(uuidString: raw) else {
            return nil
        }
        return SignInResult(userId: userId, suggestedName: nil)
    }

    func signInWithApple(idToken: String, nonce: String, suggestedName: String?) async throws -> SignInResult {
        // Mock backend ignores tokens — it just remembers a stable UUID
        // tied to whoever the device is "pretending" to be this session.
        let userId: UUID
        if let raw = defaults.string(forKey: sessionKey), let saved = UUID(uuidString: raw) {
            userId = saved
        } else {
            userId = UUID()
            defaults.set(userId.uuidString, forKey: sessionKey)
        }
        return SignInResult(userId: userId, suggestedName: suggestedName)
    }

    func signUp(email: String, password: String) async throws -> SignInResult {
        // Mock backend doesn't actually authenticate — produce a stable
        // UUID per "session" so the rest of the app can flow.
        return try await stableSession()
    }

    func signIn(email: String, password: String) async throws -> SignInResult {
        return try await stableSession()
    }

    private func stableSession() async throws -> SignInResult {
        let userId: UUID
        if let raw = defaults.string(forKey: sessionKey), let saved = UUID(uuidString: raw) {
            userId = saved
        } else {
            userId = UUID()
            defaults.set(userId.uuidString, forKey: sessionKey)
        }
        return SignInResult(userId: userId, suggestedName: nil)
    }

    func sendMagicLink(email: String) async throws {
        try? await Task.sleep(for: .milliseconds(400))
    }

    func handleAuthCallback(_ url: URL) async throws -> SignInResult {
        // Mock: reuse the same stable-UUID trick as signInWithApple.
        let userId: UUID
        if let raw = defaults.string(forKey: sessionKey), let saved = UUID(uuidString: raw) {
            userId = saved
        } else {
            userId = UUID()
            defaults.set(userId.uuidString, forKey: sessionKey)
        }
        return SignInResult(userId: userId, suggestedName: nil)
    }

    func fetchProfile(userId: UUID) async throws -> UserProfile? {
        return loadProfiles()[userId]
    }

    func createProfile(userId: UUID, displayName: String) async throws -> UserProfile {
        let profile = UserProfile(
            id: userId,
            displayName: displayName,
            bestScore: 0,
            totalGames: 0,
            createdAt: Date()
        )
        var all = loadProfiles()
        all[userId] = profile
        saveProfiles(all)
        return profile
    }

    func updateProfile(userId: UUID, displayName: String?, bestScore: Int?, totalGames: Int?) async throws -> UserProfile {
        var all = loadProfiles()
        guard var profile = all[userId] else {
            throw MockError.profileMissing
        }
        if let displayName { profile.displayName = displayName }
        if let bestScore { profile.bestScore = max(profile.bestScore, bestScore) }
        if let totalGames { profile.totalGames = totalGames }
        all[userId] = profile
        saveProfiles(all)
        return profile
    }

    func topProfiles(limit: Int) async throws -> [UserProfile] {
        loadProfiles().values
            .sorted { $0.bestScore > $1.bestScore }
            .prefix(limit)
            .map { $0 }
    }

    func signOut() async throws {
        defaults.removeObject(forKey: sessionKey)
    }

    // MARK: - Games

    private let gamesKey = "kubarik.mock.games"

    func logGame(userId: UUID, score: Int, linesCleared: Int) async throws {
        var games = loadGames()
        games.append(GameRecord(
            id: UUID(),
            userId: userId,
            score: score,
            linesCleared: linesCleared,
            playedAt: Date()
        ))
        saveGames(games)
    }

    func totalScore(userId: UUID) async throws -> Int {
        loadGames()
            .filter { $0.userId == userId }
            .map { $0.score }
            .reduce(0, +)
    }

    private func loadGames() -> [GameRecord] {
        guard let data = defaults.data(forKey: gamesKey),
              let decoded = try? JSONDecoder.kbISO8601.decode([GameRecord].self, from: data) else {
            return []
        }
        return decoded
    }

    private func saveGames(_ games: [GameRecord]) {
        guard let data = try? JSONEncoder.kbISO8601.encode(games) else { return }
        defaults.set(data, forKey: gamesKey)
    }

    // MARK: - Persistence helpers

    private func loadProfiles() -> [UUID: UserProfile] {
        guard let data = defaults.data(forKey: profilesKey),
              let decoded = try? JSONDecoder.kbISO8601.decode([String: UserProfile].self, from: data) else {
            return [:]
        }
        return Dictionary(uniqueKeysWithValues: decoded.compactMap { key, value in
            guard let uuid = UUID(uuidString: key) else { return nil }
            return (uuid, value)
        })
    }

    private func saveProfiles(_ profiles: [UUID: UserProfile]) {
        let encodable = Dictionary(uniqueKeysWithValues: profiles.map { ($0.key.uuidString, $0.value) })
        guard let data = try? JSONEncoder.kbISO8601.encode(encodable) else { return }
        defaults.set(data, forKey: profilesKey)
    }

    private enum MockError: Error {
        case profileMissing
    }
}

// MARK: - JSON coders

extension JSONDecoder {
    static var kbISO8601: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}

extension JSONEncoder {
    static var kbISO8601: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }
}
