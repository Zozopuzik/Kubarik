//
//  GameRecordQueue.swift
//  Kubarik
//
//  UserDefaults-backed FIFO of games that haven't been written to
//  Supabase yet. Two reasons a record ends up here:
//
//    1. The user is playing as a guest (no signed-in session at all).
//    2. The user IS signed in but recordGameOver's network call to
//       backend.logGame failed.
//
//  Drained by AuthManager.flushPendingRecords on bootstrap and right
//  after a successful sign-in. The queue is dumb storage — it never
//  talks to a backend directly.
//

import Foundation
import Observation

@MainActor
@Observable
final class GameRecordQueue {
    private(set) var pending: [PendingGameRecord] = []
    private let defaults = UserDefaults.standard
    private let key = "kubarik.queue.pendingGames"

    init() {
        load()
    }

    /// Append a record. Called from AuthManager.recordGameOver when
    /// either we're guest or the immediate push failed.
    func enqueue(_ record: PendingGameRecord) {
        pending.append(record)
        save()
    }

    /// Remove a single record once its backend push succeeded.
    func remove(id: UUID) {
        pending.removeAll { $0.id == id }
        save()
    }

    /// Wipe everything — used after Delete Account so the previous user's
    /// pending rows don't leak into the next sign-in.
    func clear() {
        pending = []
        defaults.removeObject(forKey: key)
    }

    // MARK: - Persistence

    private func load() {
        guard
            let data = defaults.data(forKey: key),
            let decoded = try? JSONDecoder.kbISO8601.decode([PendingGameRecord].self, from: data)
        else { return }
        pending = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder.kbISO8601.encode(pending) else { return }
        defaults.set(data, forKey: key)
    }
}
