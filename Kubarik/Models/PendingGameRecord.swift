//
//  PendingGameRecord.swift
//  Kubarik
//
//  A game session that hasn't reached Supabase yet — because the user
//  was offline, was playing as a guest, or hit a transient network blip
//  during recordGameOver. Owned by GameRecordQueue, drained by
//  AuthManager once a signed-in session + connectivity are both available.
//

import Foundation

struct PendingGameRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let score: Int
    let linesCleared: Int
    let playedAt: Date
}
