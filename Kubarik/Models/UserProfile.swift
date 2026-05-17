//
//  UserProfile.swift
//  Kubarik
//
//  Mirrors the `profiles` row in Supabase. Used everywhere we need to
//  refer to "the signed-in user" (footer, leaderboard, profile screen,
//  score sync).
//

import Foundation

struct UserProfile: Codable, Equatable, Identifiable, Hashable {
    let id: UUID
    var displayName: String
    var bestScore: Int
    var totalGames: Int
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case bestScore = "best_score"
        case totalGames = "total_games"
        case createdAt = "created_at"
    }
}
