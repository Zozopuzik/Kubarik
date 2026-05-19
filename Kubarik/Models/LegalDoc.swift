//
//  LegalDoc.swift
//  Kubarik
//
//  Tiny enum identifying the two in-app legal documents — the Welcome
//  screen uses it as an `Identifiable` payload for `.sheet(item:)`.
//

import Foundation

enum LegalDoc: String, Identifiable {
    case terms
    case privacy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .terms:   return "Terms of Use"
        case .privacy: return "Privacy Policy"
        }
    }

    var lastUpdated: String { "Last updated: May 2026" }

    var body: String {
        switch self {
        case .terms:   return Self.termsBody
        case .privacy: return Self.privacyBody
        }
    }

    // MARK: - Content
    //
    // Plain-text only. If you need rich formatting later, switch the view
    // over to AttributedString and parse markdown.

    private static let termsBody = """
By tapping Play, signing in, or otherwise using Cubariki ("the App"), you agree to these terms.

1. The App is provided as-is, free of charge, for personal entertainment. We make no guarantees about uptime, scores being preserved, or the leaderboard reflecting any particular reality.

2. You agree not to:
   • Reverse-engineer the App or attempt to access another player's data.
   • Use the App to harass, impersonate, or defraud other players.
   • Pick a display name that contains hate speech, threats, or content that targets a protected class.

3. You can stop using the App at any time. You can delete your account, profile, and game history from inside the Profile screen — the action is immediate and irreversible.

4. The App may be updated, redesigned, or discontinued at any time without notice. We'll try to give a heads-up for breaking changes, but we don't owe anyone a stable feature set.

5. Limitation of liability: to the extent allowed by law, we are not liable for any loss arising from your use of the App, including lost scores, leaderboard positions, or competitive bragging rights.

6. These terms are governed by the laws of Ukraine. If a clause is unenforceable, the rest still applies.

Questions or complaints: evgen.sabadash1337@gmail.com
"""

    private static let privacyBody = """
Cubariki ("the App") is built and operated by Yevhen Sabadash. This policy explains what the App collects, why, and how to remove it.

WHAT WE COLLECT

When you sign in:
   • Email address — used as your account identifier. We never display it publicly.
   • Auto-generated nickname (e.g. "Player_4221"). You can change it inside the Profile screen.

While you play:
   • Score and lines cleared per finished game.
   • Best score and total games played.
   • Approximate sign-up timestamp.

We do NOT collect:
   • Your name, address, phone number, photos, location, contacts, or device identifiers.
   • Anything advertising or marketing related. The App contains no third-party analytics or ad SDKs.

WHERE IT LIVES

Account and game data is stored on Supabase (a hosted Postgres database). Row-level security policies restrict each row to its owner. Anonymized public fields (nickname, best score) appear on the in-app leaderboard.

WHAT WE DO WITH IT

   • Show your stats on the Profile screen.
   • Rank you against other players on the leaderboard.
   • Persist your best score across devices once you're signed in.

We do not sell, share, or transfer your data to any third party for marketing.

HOW LONG WE KEEP IT

Until you ask us to delete it. Inside the App, tap Profile → Delete Account. This immediately removes your auth record, profile, and every game you've played. The action is irreversible.

You can also email evgen.sabadash1337@gmail.com to request deletion.

CHILDREN

The App is rated 4+ on the App Store. We do not knowingly collect data from children under 13. If a parent learns their child created an account, email us and we'll delete it.

CHANGES

If we materially change what we collect, we'll update the version date and surface a notice the next time the App launches.

CONTACT

evgen.sabadash1337@gmail.com
"""
}
