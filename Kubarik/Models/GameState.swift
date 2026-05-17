//
//  GameState.swift
//  Kubarik
//
//  The single source of truth for an in-progress game. Observable so the
//  game UI can reactively redraw whenever board, tray, or score changes.
//
//  Scoring (bumped 2× for bigger feel-good numbers):
//  - 20 points per cell placed
//  - Line clear bonus: 200 / 600 / 1000 for 1 / 2 / 3 lines in one move
//    (general: 400·N − 200)
//  - Combo bonus: each consecutive clearing move adds +200 × (combo − 1)
//  - Full-board clear: +1000
//
//  Effects channel:
//  - `lastPlaceEvent` / `lastClearEvent` are observed by the UI to drive
//    the settle-pop, particle bursts, +N float, praise callout, and
//    screen shake. They live in the model so the UI is purely reactive.
//

import Foundation
import Observation

@Observable
final class GameState {
    private(set) var board = Board()
    private(set) var tray: [Piece?] = [nil, nil, nil]
    private(set) var score: Int = 0
    private(set) var bestScore: Int = 0
    private(set) var isGameOver: Bool = false
    private(set) var justBeatBest: Bool = false
    private(set) var activeScheme: ColorScheme = .classic
    private(set) var unlockedSchemes: Set<ColorScheme> = [.classic]

    /// Chain length of consecutive clearing moves. Resets to 0 on a
    /// placement that clears nothing.
    private(set) var comboChain: Int = 0

    /// Last placement event — UI uses it to settle-pop the new cells.
    private(set) var lastPlaceEvent: PlaceEvent? = nil

    /// Last line-clear event — UI fans out particles, "+N", praise.
    private(set) var lastClearEvent: ClearEvent? = nil

    /// Haptic intent emitted at each game event.
    private(set) var hapticEvent: HapticPulse? = nil

    private let bestScoreKey = "kubarik.bestScore"

    init() {
        bestScore = UserDefaults.standard.integer(forKey: bestScoreKey)
        refillTray()
    }

    // MARK: - Public actions

    func restart() {
        board = Board()
        score = 0
        comboChain = 0
        isGameOver = false
        justBeatBest = false
        lastPlaceEvent = nil
        lastClearEvent = nil
        refillTray()
    }

    func notifyPickup() {
        hapticEvent = HapticPulse(kind: .pickup)
    }

    /// Manually dismiss the game-over flag — used by the UI when the
    /// player taps "Home" so the sheet can finish its close animation
    /// before navigation kicks in.
    func clearGameOver() {
        isGameOver = false
    }

    @discardableResult
    func place(trayIndex: Int, at origin: GridPosition) -> Bool {
        guard tray.indices.contains(trayIndex),
              let piece = tray[trayIndex],
              board.canPlace(piece, at: origin)
        else { return false }

        // 1. Paint the piece
        let placedAbsolute = piece.shape.cells.map { origin.offset(by: $0) }
        board = board.placing(piece, at: origin)
        let placementScore = piece.shape.cells.count * 20
        score += placementScore
        tray[trayIndex] = nil

        // 2. Emit placement event for settle-pop animation
        lastPlaceEvent = PlaceEvent(placedCells: placedAbsolute, color: piece.color)

        // 3. Clear full lines
        let full = board.fullLines()
        let lineCount = full.rows.count + full.cols.count
        var emittedHaptic = HapticPulse(kind: .placement(cells: piece.shape.cells.count))

        if lineCount > 0 {
            let clearedCells = collectClearedCells(rows: full.rows, cols: full.cols)
            board = board.clearing(rows: full.rows, cols: full.cols)

            let lineScore = GameState.lineClearScore(lineCount)
            comboChain += 1
            let comboBonus = comboChain > 1 ? (comboChain - 1) * 200 : 0
            let totalLineDelta = lineScore + comboBonus
            score += totalLineDelta

            let fullClear = board.isEmpty
            if fullClear {
                score += 1000
                unlockNextSchemeIfAvailable()
                emittedHaptic = HapticPulse(kind: .fullClear)
            } else {
                emittedHaptic = HapticPulse(kind: .linesCleared(lineCount))
            }

            lastClearEvent = ClearEvent(
                clearedCells: clearedCells,
                dominantColor: piece.color,
                lineCount: lineCount,
                combo: comboChain,
                scoreDelta: placementScore + totalLineDelta + (fullClear ? 1000 : 0)
            )
        } else {
            // Placement without clear breaks the combo chain.
            comboChain = 0
        }
        hapticEvent = emittedHaptic

        // 4. Refill tray if needed
        if tray.allSatisfy({ $0 == nil }) {
            refillTray()
        }

        // 5. Game-over check
        updateGameOverFlag()
        return true
    }

    @discardableResult
    func setScheme(_ scheme: ColorScheme) -> Bool {
        guard unlockedSchemes.contains(scheme) else { return false }
        activeScheme = scheme
        return true
    }

    // MARK: - Scoring helper

    static func lineClearScore(_ count: Int) -> Int {
        guard count > 0 else { return 0 }
        return 400 * count - 200
    }

    // MARK: - Difficulty pool

    var currentPool: [PieceShape] {
        switch score {
        case ..<400:  return PieceShape.easyPool
        case ..<1200: return PieceShape.mediumPool
        default:      return PieceShape.hardPool
        }
    }

    // MARK: - Refill (anti-deadlock + helpful bias + uniqueness)

    private func refillTray() {
        let pool = currentPool
        let biasSmall = boardNeedsHelpfulPiece()

        for _ in 0..<30 {
            let candidate = generateCandidateTray(pool: pool, biasSmall: biasSmall)
            if candidate.contains(where: { board.hasAnyPlacement(for: $0) }) {
                tray = candidate
                return
            }
        }
        tray = (0..<3).map { _ in Piece.random(scheme: activeScheme, pool: pool) }
    }

    private func generateCandidateTray(pool: [PieceShape], biasSmall: Bool) -> [Piece] {
        let palette = activeScheme.tileColors
        var pieces: [Piece] = []
        var usedShapeIds = Set<String>()

        for slot in 0..<3 {
            let remaining = pool.filter { !usedShapeIds.contains($0.id) }
            let drawFrom = remaining.isEmpty ? pool : remaining

            let shape: PieceShape
            if slot == 0, biasSmall {
                shape = sampleWithSmallBias(pool: drawFrom)
            } else {
                shape = drawFrom.randomElement() ?? PieceShape.mono
            }
            usedShapeIds.insert(shape.id)

            let color = palette.randomElement() ?? TileColor.coral
            pieces.append(Piece(shape: shape, color: color))
        }
        return pieces
    }

    private func sampleWithSmallBias(pool: [PieceShape]) -> PieceShape {
        var weighted: [PieceShape] = []
        for shape in pool {
            let weight: Int
            switch shape.cells.count {
            case ..<4: weight = 4
            case 4:    weight = 2
            default:   weight = 1
            }
            for _ in 0..<weight { weighted.append(shape) }
        }
        return weighted.randomElement() ?? PieceShape.mono
    }

    private func boardNeedsHelpfulPiece() -> Bool {
        let threshold = Board.size - 2
        for r in 0..<Board.size {
            let count = board.cells[r].lazy.filter({ $0 != nil }).count
            if count >= threshold { return true }
        }
        for c in 0..<Board.size {
            var count = 0
            for r in 0..<Board.size where board.cells[r][c] != nil {
                count += 1
            }
            if count >= threshold { return true }
        }
        return false
    }

    // MARK: - Internals

    private func collectClearedCells(rows: [Int], cols: [Int]) -> [GridPosition] {
        var set = Set<GridPosition>()
        for r in rows {
            for c in 0..<Board.size {
                set.insert(GridPosition(row: r, col: c))
            }
        }
        for c in cols {
            for r in 0..<Board.size {
                set.insert(GridPosition(row: r, col: c))
            }
        }
        return Array(set)
    }

    private func updateGameOverFlag() {
        let active = tray.compactMap { $0 }
        if active.isEmpty {
            isGameOver = false
            return
        }
        let canPlay = active.contains(where: { board.hasAnyPlacement(for: $0) })
        isGameOver = !canPlay
        if isGameOver {
            justBeatBest = score > bestScore
            if justBeatBest {
                bestScore = score
                UserDefaults.standard.set(bestScore, forKey: bestScoreKey)
            }
            hapticEvent = HapticPulse(kind: .gameOver)
        }
    }

    private func unlockNextSchemeIfAvailable() {
        let order: [ColorScheme] = [.classic, .sunset, .ocean]
        for scheme in order where !unlockedSchemes.contains(scheme) {
            unlockedSchemes.insert(scheme)
            return
        }
    }
}
