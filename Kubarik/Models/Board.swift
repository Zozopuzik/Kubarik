//
//  Board.swift
//  Kubarik
//
//  The 8×8 grid. Pure value type — all mutations return a new Board so
//  callers can decide when to commit (useful for previewing a placement
//  without altering live state).
//
//  Coordinates: row 0 is the top, col 0 is the left.
//

import Foundation

struct Board: Equatable {
    static let size = 8

    private(set) var cells: [[TileColor?]]

    init() {
        cells = Array(
            repeating: Array(repeating: nil, count: Board.size),
            count: Board.size
        )
    }

    subscript(_ pos: GridPosition) -> TileColor? {
        cells[pos.row][pos.col]
    }

    // MARK: - Queries

    func isInBounds(_ pos: GridPosition) -> Bool {
        (0..<Board.size).contains(pos.row) && (0..<Board.size).contains(pos.col)
    }

    /// Can `piece` be placed with its anchor cell at `origin`? Checks both
    /// bounds and existing occupancy.
    func canPlace(_ piece: Piece, at origin: GridPosition) -> Bool {
        for cell in piece.shape.cells {
            let target = origin.offset(by: cell)
            guard isInBounds(target) else { return false }
            guard cells[target.row][target.col] == nil else { return false }
        }
        return true
    }

    /// Anywhere on the board this piece could legally go. Used for game-over
    /// detection — if no piece in the tray has any landing spot, the game ends.
    func hasAnyPlacement(for piece: Piece) -> Bool {
        for r in 0..<Board.size {
            for c in 0..<Board.size {
                if canPlace(piece, at: GridPosition(row: r, col: c)) {
                    return true
                }
            }
        }
        return false
    }

    /// Whether the board has zero filled cells. Used to detect a "full clear"
    /// — the trigger for unlocking new skin sets.
    var isEmpty: Bool {
        cells.allSatisfy { row in row.allSatisfy { $0 == nil } }
    }

    // MARK: - Mutations (return new boards)

    /// Returns a new board with the piece's cells painted in. The caller
    /// must have verified the placement with `canPlace` first.
    func placing(_ piece: Piece, at origin: GridPosition) -> Board {
        var copy = self
        for cell in piece.shape.cells {
            let target = origin.offset(by: cell)
            copy.cells[target.row][target.col] = piece.color
        }
        return copy
    }

    /// Indices of rows and columns that are completely filled.
    func fullLines() -> (rows: [Int], cols: [Int]) {
        var rows: [Int] = []
        var cols: [Int] = []
        for r in 0..<Board.size where cells[r].allSatisfy({ $0 != nil }) {
            rows.append(r)
        }
        for c in 0..<Board.size where (0..<Board.size).allSatisfy({ cells[$0][c] != nil }) {
            cols.append(c)
        }
        return (rows, cols)
    }

    /// Returns a new board with the given rows and columns cleared.
    func clearing(rows: [Int], cols: [Int]) -> Board {
        var copy = self
        for r in rows {
            for c in 0..<Board.size {
                copy.cells[r][c] = nil
            }
        }
        for c in cols {
            for r in 0..<Board.size {
                copy.cells[r][c] = nil
            }
        }
        return copy
    }
}
