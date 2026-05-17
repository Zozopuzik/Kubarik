//
//  AuthState.swift
//  Kubarik
//
//  Three states the rest of the app cares about:
//  - `loading`     — initial bootstrap (checking persisted session)
//  - `guest`       — no signed-in user; play locally, score is private
//  - `needsNickname(userId)` — Apple sign-in succeeded but the user has
//    no `profiles` row yet — show the nickname sheet before letting
//    them back into the game.
//  - `signedIn(profile)` — fully set up; can sync scores + see leaderboard.
//

import Foundation

enum AuthState: Equatable {
    case loading
    case guest
    case needsNickname(userId: UUID)
    case signedIn(profile: UserProfile)

    var profile: UserProfile? {
        if case .signedIn(let p) = self { return p }
        return nil
    }

    var isSignedIn: Bool {
        if case .signedIn = self { return true }
        return false
    }
}
