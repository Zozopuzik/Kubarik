//
//  GameRecord.swift
//  Kubarik
//
//  One finished game session, persisted to the Supabase `games` table.
//  Used to derive the lifetime "total points" stat shown in Profile.
//

import Foundation

struct GameRecord: Codable, Equatable, Identifiable {
    let id: UUID
    let userId: UUID
    let score: Int
    let linesCleared: Int
    let playedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case score
        case linesCleared = "lines_cleared"
        case playedAt = "played_at"
    }
}

/// Payload used when *inserting* — `id` and `played_at` are filled by
/// Postgres defaults, so we omit them.
struct NewGameRecord: Encodable {
    let userId: UUID
    let score: Int
    let linesCleared: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case score
        case linesCleared = "lines_cleared"
    }
}
