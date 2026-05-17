# Kubariki

A Block-Blast-style puzzle game built **from scratch in SwiftUI in a single day**, learning Swift along the way. Drag pieces from a tray onto a 7×7 grid, clear full rows and columns, chase combos.

[![iOS](https://img.shields.io/badge/iOS-17%2B-black?logo=apple)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange?logo=swift)](https://www.swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-✓-blue)](https://developer.apple.com/xcode/swiftui/)
[![Supabase](https://img.shields.io/badge/Supabase-Auth%20%2B%20Postgres-3ECF8E?logo=supabase)](https://supabase.com)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

<!-- TODO: drop a hero screenshot or 5-second gameplay GIF here -->
<!-- ![Hero](docs/hero.gif) -->

---

## What's inside

### Gameplay
- **39 piece shapes** across monominoes, dominoes, triominoes, tetrominoes, pentominoes, squares, and rectangles — with weighted spawn so lines and squares dominate
- **Progressive difficulty** — pools widen as score climbs (`< 400` → easy / `< 1200` → medium / `1200+` → hard)
- **Magnetic snap** — finger missed? piece snaps to the nearest legal cell (Manhattan radius 1–2)
- **Will-clear preview** — empty cells in a row/column that will clear on drop ghost-fill with the piece color
- **Combo chain** with multiplier — 100/300/500 base for 1/2/3 lines, `+200 × (combo-1)` bonus

### Feel layer
- **Settle pop** spring-bounce on every placed cell
- **Praise flash** callouts that escalate: NICE → COMBO → WOW → MEGA → ON FIRE
- **Particle bursts** fanning radially out of cleared cells
- **Floating "+N"** score popup at board center
- **Screen shake** scaled by line count + combo
- **3-level haptics** (off / medium / high), each level chains multiple UIImpact pulses for a thick "boom-boom" rather than a thin tap

### Audio
- Two looping background tracks (welcome + game) with **AVFoundation crossfade** — both play simultaneously during a transition, never a cut
- Short jingle on game over
- `.ambient` session category so the game yields to the user's Spotify

### Auth + cloud
- **Supabase** auth (email + password) — `AuthBackend` protocol behind it so the mock and live impls are swappable
- **`profiles` + `games` tables** with RLS, server-side `get_user_total_score(p_user_id)` aggregation RPC
- **Top-100 leaderboard** with own-row highlight
- **Auto-generated nicknames** (`Player_NNNN`), in-app rename via pencil sheet
- Local `bestScore` persisted in `UserDefaults`, synced to cloud after every game over

### Screens
- **Splash** — three letter cubes (K/U/B) drop in, wordmark fades up
- **Welcome** — animated entrance: background cubes fly in from edges, letter tiles drop one-by-one with spring overshoot, tagline + CTA fade in, PlayButton pulses after 2s
- **Game** — board + tray + drag follower + effects overlay + game-over sheet
- **Leaderboard** — top 100 with own-row highlight
- **Profile** — Info/Preferences tabs, avatar cube, stats grid (BEST / TOTAL / GAMES / LINES), rename, sign out
- **Settings** — Music toggle + Haptics 3-way picker

---

## Architecture

Every shared service is an `@Observable` class hoisted to `ContentView` and pushed down through `.environment(...)`:

```
ContentView
├── @State auth     = AuthManager()        ← signed-in profile + leaderboard fetches
├── @State audio    = AudioPlayer()        ← crossfading background music
├── @State prefs    = PreferencesStore()   ← UserDefaults-backed settings
└── NavigationStack
    ├── WelcomeView
    ├── GameView
    │   ├── @State game     = GameState()       ← board + tray + score + events
    │   ├── @State haptics  = HapticEngine()
    │   └── @State shake    = ScreenShakeDriver()
    ├── LeaderboardView
    ├── ProfileView
    └── SettingsView
```

### Protocol-based backend swap

`AuthBackend` defines what auth + leaderboard + games tracking needs to do. Two implementations:

```swift
class MockAuthBackend: AuthBackend       // UserDefaults, no network — used for previews + offline dev
class SupabaseAuthBackend: AuthBackend   // talks to the real project
```

Wiring is one line in `AuthManager`:

```swift
init(backend: AuthBackend = SupabaseAuthBackend()) { ... }
```

The rest of the app speaks `AuthState` (`.loading / .guest / .signedIn(profile)`), never imports `Supabase`. Means tests + previews + offline builds are trivial.

### Event-driven effects layer

`GameState` publishes two events the UI observes via `.onChange`:

```swift
private(set) var lastPlaceEvent: PlaceEvent?   // → settle-pop animation
private(set) var lastClearEvent: ClearEvent?   // → particles + "+N" + praise + screen shake
private(set) var hapticEvent: HapticPulse?     // → HapticEngine.play
```

Model layer stays free of UIKit / SwiftUI types — `HapticEngine` lives in the view layer and maps `HapticPulse.Kind` to concrete `UIImpactFeedbackGenerator` chains.

### Drag handling

- Drag gesture lives in tray slots, registered with `.highPriorityGesture` to beat the `NavigationStack` back-swipe recognizer that otherwise eats the first frame
- Finger position reported in a named `"game"` coordinate space; `BoardView` writes its own frame into the same space via background `GeometryReader`
- `computeHoverOrigin(...)` converts finger → grid cell, then `nearestValidOrigin(...)` searches outward in expanding Manhattan rings for the magnetic snap
- Will-clear prediction cached in `@State` and only recomputed when the hovered cell changes (not on every pixel of finger movement)

---

## Tech stack

| Layer | Tool |
|---|---|
| UI | SwiftUI, iOS 17+ (`@Observable` macro) |
| Animation | Native SwiftUI `.spring`, `.easeInOut`, custom `withAnimation` chains via async `Task` sleeps |
| Haptics | `UIImpactFeedbackGenerator` chained sequences (richer than `.sensoryFeedback`) |
| Audio | `AVAudioPlayer` with manual crossfade between two slots |
| Auth | Supabase Swift SDK (`Auth` + `PostgREST`) |
| Persistence | `UserDefaults` for local state, Supabase Postgres + RLS for cloud |
| Navigation | iOS 16+ value-based `NavigationStack(path:)` with custom `AppRoute` enum |
| Dependency injection | `@Environment(_:.self)` for `@Observable` services |

---

## Folder map

```
Kubarik/
├── KubarikApp.swift          ← app entry
├── ContentView.swift         ← splash + nav root, owns shared services
├── Audio/                    ← Suno-generated soundtrack
├── Models/
│   ├── Board, GameState      ← game logic (pure, no UI)
│   ├── Piece, PieceShape     ← shape catalog with weighted pools
│   ├── UserProfile, GameRecord, AuthState
│   ├── Preferences, HapticLevel, HapticPulse
│   └── PlaceEvent, ClearEvent, PraiseTier, DragState
├── Navigation/
│   └── AppRoute.swift        ← every push destination
├── Services/
│   ├── AuthBackend (protocol)
│   ├── MockAuthBackend, SupabaseAuthBackend
│   ├── AuthManager           ← public face of auth
│   ├── AudioPlayer
│   └── SupabaseConfig
├── Theme/
│   ├── Color+Hex, Palette, TileColor
└── Views/
    ├── Splash/SplashView
    ├── Welcome/WelcomeView, WelcomeData
    ├── Auth/EmailSignInSheet
    ├── Game/
    │   ├── GameView          ← orchestrates everything
    │   ├── BoardView, BoardCellView, BoardSurface
    │   ├── PiecePreview, TrayView, DragFollowerView
    │   ├── GameOverSheet
    │   └── Effects/
    │       ├── PraiseFlash, Particle, FloatScoreView
    │       ├── ScreenShake, HapticEngine
    ├── Leaderboard/LeaderboardView
    ├── Profile/
    │   ├── ProfileView, NicknameEditSheet, PrefControls
    └── Settings/SettingsView
```

---

## Setup

1. Clone the repo
2. Open `Kubarik.xcodeproj` in **Xcode 16+** (iOS 17 target)
3. The Supabase Swift SDK is bundled as a Swift Package — Xcode resolves on open
4. Create your local Supabase credentials file:

   ```bash
   cp Kubarik/Services/SupabaseConfig-local.example.swift \
      Kubarik/Services/SupabaseConfig-local.swift
   ```

   Uncomment the body and fill in your project values:

   ```swift
   import Foundation

   enum SupabaseConfigLocal {
       static let projectURLString = "https://YOUR-PROJECT.supabase.co"
       static let anonKey = "YOUR_SUPABASE_ANON_KEY"
   }
   ```

   `*-local.swift` is gitignored — your real keys stay on your machine. The committed `SupabaseConfig.swift` just reads from this enum, so the project compiles only once you've supplied real values.

5. Run the SQL below to create `profiles` + `games` tables and the `get_user_total_score` RPC

### Supabase schema

```sql
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  display_name text not null,
  best_score int not null default 0,
  total_games int not null default 0,
  created_at timestamp with time zone default now()
);

create table public.games (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  score int not null,
  lines_cleared int not null default 0,
  played_at timestamp with time zone default now()
);

-- RLS: read public, write own
alter table public.profiles enable row level security;
create policy "public read" on profiles for select using (true);
create policy "own write"  on profiles for update using (auth.uid() = id);
create policy "own insert" on profiles for insert with check (auth.uid() = id);

alter table public.games enable row level security;
create policy "public read" on games for select using (true);
create policy "own insert" on games for insert with check (auth.uid() = user_id);

create index profiles_best_score_idx on profiles (best_score desc);
create index games_user_id_idx on games (user_id);

create or replace function public.get_user_total_score(p_user_id uuid)
returns int language sql stable as $$
  select coalesce(sum(score), 0)::int from public.games where user_id = p_user_id;
$$;

-- Account deletion. Runs as the function owner (postgres) so it can
-- reach into auth.users; rls is enforced via auth.uid() inside the body.
-- Required for App Store Review guideline 5.1.1(v).
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;
  delete from public.games    where user_id = uid;
  delete from public.profiles where id      = uid;
  delete from auth.users      where id      = uid;
end;
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
```

---

## What this project doesn't have (yet)

Honest list, because portfolio:

- **No tests** — game logic is pure value-types so it's testable; nothing has been wired into XCTest yet
- **No Apple Sign In** — works in code (`signInWithApple` lives in `AuthBackend`), but requires Apple Developer Program ($99/yr) capability
- **No multiplayer** — Supabase Realtime is already in the SDK bundle, but no `Realtime` views yet
- **No skins unlocked** — `ColorScheme.sunset` / `ColorScheme.ocean` are defined but the full-board-clear unlock loop is a one-line `unlockNextSchemeIfAvailable()` placeholder; the UI to switch sets is missing

---

## Built by

[Yevhen Sabadash](https://github.com/Zozopuzik) — 5 years of React Native, first Swift project. Built in ~4 hours with [Claude Code](https://claude.com/claude-code) as a pair programmer.

License: MIT.
