# App Store Connect — Submission Copy

Ready-to-paste text for the Cubariki App Store listing. Counts are checked against Apple's limits. Update anything that doesn't sound right, then copy into [appstoreconnect.apple.com](https://appstoreconnect.apple.com).

---

## Identity

| Field | Value | Limit |
|---|---|---|
| **App Name** | `Cubariki` | 30 chars |
| **Subtitle** | `Drop · Pop · Chill` | 30 chars |
| **Bundle ID** | `com.sds.Kubarik` | — |
| **SKU** | `kubariki-ios-001` | — |
| **Primary language** | English (U.S.) | — |
| **Copyright** | `© 2026 Yevhen Sabadash` | — |

> ⚠️ Check `Cubariki` is not already taken on the App Store before you start the listing — search [apps.apple.com](https://apps.apple.com) first. Fallback names: `Cubariki: Block Puzzle`, `Kubarik Blocks`, `Kubarik`.

---

## Promotional text — 170 chars

Updatable anytime without re-review. Use it for launch promos, sales, or "new in this version" callouts.

```
Drop pieces. Clear lines. Chain combos. A cozy block-puzzle take with juicy haptics, particle bursts, and a chill soundtrack. Built solo, in a weekend.
```

_(149 chars — room to spare)_

---

## Description — 4000 chars max

```
Drop pieces onto a 7×7 grid. Snap blocks into rows and columns. Chain combos until the board explodes with particles and screen shake.

Cubariki is a cozy take on the block-puzzle genre — built for one-handed play and quick chill sessions.

FEATURES

• 39 piece shapes — monominoes, lines, squares, L-shapes, T-pieces, big rectangles
• Progressive difficulty — the spawn pool widens as your score climbs
• Magnetic snap — missed by a hair? Pieces snap to the nearest legal cell
• Will-clear preview — soon-to-clear cells glow in advance so you can see the combo
• Combo chains with escalating multipliers — 100 / 300 / 500 for 1/2/3 lines, plus bonus on combo
• Dopamine effects — settle-pop bounce on every placed cell, particle bursts on clears, +N score popup, praise callouts (NICE → COMBO → WOW → MEGA → ON FIRE), screen shake scaled by combo
• Three haptic intensities — Off / Medium / High, with chained pulses for a thick boom-boom feel
• Two looping soundtracks with smooth crossfade between menu and game
• Top-100 leaderboard with your row highlighted
• Auto-generated nicknames you can rename anytime
• Account deletion built in — wipe everything from inside the app

BUILT TO LEARN

Cubariki is the first iOS game by Yevhen Sabadash (5 years on React Native). Built solo, end-to-end, in a single weekend to dive into Swift and SwiftUI. The code is open — github.com/Zozopuzik/Kubarik

PRIVACY

The app stores only your email, nickname, and game scores — no analytics, no ads, no tracking. You can delete everything from inside the app.

SUPPORT

Bug or idea? Tap Settings → Help us → Report a bug or idea inside the app, or open an issue at github.com/Zozopuzik/Kubarik/issues
```

_(≈ 1,650 chars — plenty of room to expand if you want screenshots-style breakouts)_

---

## Keywords — 100 chars max

Comma-separated, no spaces after commas (saves chars). Don't include the app name (already indexed). Apple flags duplicates / plurals as wasted slots.

```
block,puzzle,blast,casual,zen,arcade,grid,chill,combo,relax,brain,offline,bricks,daily,fun
```

_(96 chars)_

---

## URLs

| Field | URL | Required |
|---|---|---|
| **Privacy Policy URL** | `https://zozopuzik.github.io/Kubarik/privacy/` | ✅ Mandatory |
| **Marketing URL** | `https://zozopuzik.github.io/Kubarik/` | Optional |
| **Support URL** | `https://github.com/Zozopuzik/Kubarik/issues` | ✅ Mandatory |
| **Terms of Use URL** _(in EULA section)_ | `https://zozopuzik.github.io/Kubarik/terms/` | Optional but nice |

> Pages must be live before submission. After committing the `docs/` folder, enable GitHub Pages in repo Settings → Pages → Source: `main` branch / `/docs` folder.

---

## Category

- **Primary:** Games → Puzzle
- **Secondary:** Games → Casual

---

## Age Rating

`4+` — no objectionable content. Questionnaire answers:

| Question | Answer |
|---|---|
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |
| Sexual Content or Nudity | None |
| Profanity or Crude Humor | None |
| Alcohol, Tobacco, or Drug Use | None |
| Mature/Suggestive Themes | None |
| Horror/Fear Themes | None |
| Prolonged Graphic or Sadistic Realistic Violence | None |
| Graphic Sexual Content and Nudity | None |
| Gambling and Contests | None |
| Unrestricted Web Access | No |
| Gambling Simulator | No |
| Medical/Treatment Information | No |
| Mature Themes | None |

---

## App Privacy ("Nutrition Label")

Apple's privacy questionnaire. Answers:

### Data collected

| Data Type | Linked to User? | Used For |
|---|---|---|
| **Email Address** | Yes | App Functionality (account identifier) |
| **User Content** (display name) | Yes | App Functionality |
| **Other Usage Data** (game scores, lines cleared) | Yes | App Functionality |

### Data NOT collected

- Contact Info (other than email)
- Health & Fitness
- Financial Info
- Location
- Sensitive Info
- Contacts
- Photos
- Audio Data
- Search History
- Browsing History
- Identifiers (other than email)
- Purchases
- Diagnostics (no crashlytics)
- Advertising Data

### Tracking

`No tracking across apps or websites owned by other companies.`

---

## App Review Information

For Apple's reviewer team. Cubariki uses **Sign in with Apple as the only sign-in method**, so no demo username/password is needed — the reviewer signs in with their own Apple ID.

```
First Name: Yevhen
Last Name: Sabadash
Phone: +380 96 832 3305
Email: evgen.sabadash1337@gmail.com

KEY POINTS FOR REVIEW

• Sign-in is OPTIONAL. The full game is playable as a guest — tap PLAY on the welcome screen.

• The only sign-in method is Sign in with Apple (native, via AuthenticationServices). No demo account needed — please use any Apple ID to test signed-in features (Profile, Leaderboard, score sync).

• Guideline 5.1.1 (account deletion) — path: Welcome → Sign in with Apple → tap "person" icon → Profile → Info tab → DELETE ACCOUNT button (red, under Sign Out). One tap, single confirmation, wipes auth.users + profile + every game row in one transaction via a SECURITY DEFINER Postgres function.

• Guideline 4.3 (originality) — Cubariki is a one-person creative work with unique mechanics: magnetic snap (Manhattan radius search), 39 weighted piece shapes (vs the genre standard ~20), escalating praise callouts (NICE → COMBO → WOW → MEGA → ON FIRE), chained 3-level haptics, and custom soundtrack crossfade. Open source — github.com/Zozopuzik/Kubarik

• No IAP, no subscriptions, no ads, no third-party analytics or tracking SDKs.

• Privacy policy: https://zozopuzik.github.io/Kubarik/privacy/
```

---

## Build

| Field | Value |
|---|---|
| Version | `1.0.0` |
| Build Number | `1` |
| Minimum iOS | `17.0` |
| Device Family | iPhone only (iPad mode: scaled) |
| Orientation | Portrait |
| Game Center | No |
| In-App Purchases | None |

---

## Screenshots — required

**6.9" Display (iPhone 16 Pro Max)** — 1320 × 2868 px. Minimum 3, max 10.

Suggested set (5 shots):

1. **Welcome screen** with the C/U/B/A/R/I/K/I letter tiles + PLAY pulsing
2. **Active gameplay** — board half-filled, drag in progress, will-clear preview glowing
3. **Combo moment** — particles erupting from cleared row, "WOW" praise flash visible, +500 popup floating
4. **Game over sheet** — score, best, total games stats
5. **Leaderboard** — top players with own-row highlight

Optional 6th: **Profile** with stats grid (BEST / TOTAL / GAMES / LINES).

**How to capture:**
```
1. In Xcode: open Window → Devices and Simulators → start iPhone 16 Pro Max sim
2. Run Cubariki on it (Cmd+R while sim selected)
3. In Simulator: File → Screenshot (Cmd+S) — saves to Desktop at native resolution
4. Drop into Figma / Sketch with marketing copy overlays if desired
5. Final dimensions must be exactly 1320 × 2868 for 6.9"
```

You only NEED 6.9" — Apple auto-scales for smaller phones. But you can add 6.7" (1290 × 2796) and 5.5" (1242 × 2208) if you want pixel-perfect on older devices.

**App Preview Video (optional but recommended)**: 15–30 sec gameplay loop. Same capture flow, use Cmd+R to record screen. Trim in QuickTime, export at 1080p 30fps.

---

## Pre-submission checklist

- [x] Apple Developer Program enrollment approved
- [x] Bundle ID `com.sds.Kubarik` registered with Sign In with Apple capability
- [x] Sign in with Apple wired end-to-end + Supabase Apple provider configured
- [x] GitHub Pages live: `https://zozopuzik.github.io/Kubarik/privacy/` returns 200
- [ ] App listing created in App Store Connect
- [ ] Screenshots taken at 1320 × 2868 (min 3)
- [ ] Build archived in Xcode and uploaded via Organizer
- [ ] All metadata above filled in App Store Connect
- [ ] Age Rating questionnaire submitted
- [ ] App Privacy ("Nutrition Label") submitted
- [ ] App Review Information filled
- [ ] Submit for Review
- [ ] Pray to the review gods 🙏

---

_Drafted 2026-05-17 — adjust before submission._
