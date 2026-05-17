//
//  AppRoute.swift
//  Kubarik
//
//  All push-style destinations the app navigates to. Living as a single
//  enum makes it cheap to add a screen — just add a case and handle it
//  in the root NavigationStack's destination switch.
//

import Foundation

enum AppRoute: Hashable {
    case game
    case leaderboard
    case profile
    case settings
}
