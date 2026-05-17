//
//  PieceShape.swift
//  Kubarik
//
//  Catalog of every shape the game can spawn. A shape is a list of cell
//  offsets from the piece's top-left anchor (row 0, col 0). Each rotation
//  is its own entry — flat data is easier to reason about and tune than
//  matrix rotation at runtime.
//
//  Conventions:
//  - `(0, 0)` is the top-left cell of the shape's bounding box.
//  - Every shape is normalized: at least one cell touches row 0 *and* at
//    least one touches col 0 (no empty top row / left column).
//

import Foundation

struct PieceShape: Hashable, Identifiable {
    let id: String
    let cells: [GridPosition]

    var width: Int {
        (cells.map { $0.col }.max() ?? 0) + 1
    }

    var height: Int {
        (cells.map { $0.row }.max() ?? 0) + 1
    }
}

/// Local shorthand for building a cell list inline. Named `at` rather than
/// `cells` to avoid shadowing PieceShape's `cells` property during static
/// initialization (Swift resolves the property name first inside the init,
/// causing "Cannot use instance member" errors).
private func at(_ pairs: (Int, Int)...) -> [GridPosition] {
    pairs.map { GridPosition(row: $0.0, col: $0.1) }
}

extension PieceShape {

    // MARK: - 1 cell

    static let mono = PieceShape(id: "mono", cells: at((0, 0)))

    // MARK: - 2 cells (domino)

    static let line2H = PieceShape(id: "line2H", cells: at((0, 0), (0, 1)))
    static let line2V = PieceShape(id: "line2V", cells: at((0, 0), (1, 0)))

    // MARK: - 3 cells (triomino)

    static let line3H = PieceShape(id: "line3H", cells: at((0, 0), (0, 1), (0, 2)))
    static let line3V = PieceShape(id: "line3V", cells: at((0, 0), (1, 0), (2, 0)))

    // Small L-triomino, 4 orientations. Corner indicates where the L "elbow" sits.
    static let triL_TL = PieceShape(id: "triL_TL", cells: at((0, 0), (0, 1), (1, 0)))
    static let triL_TR = PieceShape(id: "triL_TR", cells: at((0, 0), (0, 1), (1, 1)))
    static let triL_BL = PieceShape(id: "triL_BL", cells: at((0, 0), (1, 0), (1, 1)))
    static let triL_BR = PieceShape(id: "triL_BR", cells: at((0, 1), (1, 0), (1, 1)))

    // MARK: - 4 cells (tetromino)

    static let line4H = PieceShape(id: "line4H", cells: at((0, 0), (0, 1), (0, 2), (0, 3)))
    static let line4V = PieceShape(id: "line4V", cells: at((0, 0), (1, 0), (2, 0), (3, 0)))

    static let square2x2 = PieceShape(id: "square2x2", cells: at((0, 0), (0, 1), (1, 0), (1, 1)))

    // Tetris-style L, 4 rotations
    static let L_r0 = PieceShape(id: "L_r0",   cells: at((0, 0), (1, 0), (2, 0), (2, 1)))
    static let L_r1 = PieceShape(id: "L_r1",   cells: at((0, 0), (0, 1), (0, 2), (1, 0)))
    static let L_r2 = PieceShape(id: "L_r2",   cells: at((0, 0), (0, 1), (1, 1), (2, 1)))
    static let L_r3 = PieceShape(id: "L_r3",   cells: at((0, 2), (1, 0), (1, 1), (1, 2)))

    // Tetris-style J (mirror of L), 4 rotations
    static let J_r0 = PieceShape(id: "J_r0",   cells: at((0, 1), (1, 1), (2, 0), (2, 1)))
    static let J_r1 = PieceShape(id: "J_r1",   cells: at((0, 0), (1, 0), (1, 1), (1, 2)))
    static let J_r2 = PieceShape(id: "J_r2",   cells: at((0, 0), (0, 1), (1, 0), (2, 0)))
    static let J_r3 = PieceShape(id: "J_r3",   cells: at((0, 0), (0, 1), (0, 2), (1, 2)))

    // T tetromino, 4 rotations
    static let T_r0 = PieceShape(id: "T_r0",   cells: at((0, 0), (0, 1), (0, 2), (1, 1)))
    static let T_r1 = PieceShape(id: "T_r1",   cells: at((0, 0), (1, 0), (1, 1), (2, 0)))
    static let T_r2 = PieceShape(id: "T_r2",   cells: at((0, 1), (1, 0), (1, 1), (1, 2)))
    static let T_r3 = PieceShape(id: "T_r3",   cells: at((0, 1), (1, 0), (1, 1), (2, 1)))

    // S tetromino, 2 rotations
    static let S_r0 = PieceShape(id: "S_r0",   cells: at((0, 1), (0, 2), (1, 0), (1, 1)))
    static let S_r1 = PieceShape(id: "S_r1",   cells: at((0, 0), (1, 0), (1, 1), (2, 1)))

    // Z tetromino, 2 rotations
    static let Z_r0 = PieceShape(id: "Z_r0",   cells: at((0, 0), (0, 1), (1, 1), (1, 2)))
    static let Z_r1 = PieceShape(id: "Z_r1",   cells: at((0, 1), (1, 0), (1, 1), (2, 0)))

    // MARK: - 5 cells (pentomino — selected variants)

    static let line5H = PieceShape(id: "line5H", cells: at((0, 0), (0, 1), (0, 2), (0, 3), (0, 4)))
    static let line5V = PieceShape(id: "line5V", cells: at((0, 0), (1, 0), (2, 0), (3, 0), (4, 0)))

    // Big L (3×3 corner), 4 rotations — anchor cell is the corner.
    static let bigL_r0 = PieceShape(id: "bigL_r0", cells: at((0, 0), (1, 0), (2, 0), (2, 1), (2, 2)))
    static let bigL_r1 = PieceShape(id: "bigL_r1", cells: at((0, 0), (0, 1), (0, 2), (1, 0), (2, 0)))
    static let bigL_r2 = PieceShape(id: "bigL_r2", cells: at((0, 0), (0, 1), (0, 2), (1, 2), (2, 2)))
    static let bigL_r3 = PieceShape(id: "bigL_r3", cells: at((0, 2), (1, 2), (2, 0), (2, 1), (2, 2)))

    // Plus / cross (5 cells)
    static let plus = PieceShape(id: "plus", cells: at((0, 1), (1, 0), (1, 1), (1, 2), (2, 1)))

    // U shape (5 cells)
    static let u = PieceShape(id: "u", cells: at((0, 0), (0, 2), (1, 0), (1, 1), (1, 2)))

    // MARK: - Rectangles & blocks

    static let rect2x3 = PieceShape(id: "rect2x3", cells: at(
        (0, 0), (0, 1), (0, 2),
        (1, 0), (1, 1), (1, 2)
    ))

    static let rect3x2 = PieceShape(id: "rect3x2", cells: at(
        (0, 0), (0, 1),
        (1, 0), (1, 1),
        (2, 0), (2, 1)
    ))

    static let square3x3 = PieceShape(id: "square3x3", cells: at(
        (0, 0), (0, 1), (0, 2),
        (1, 0), (1, 1), (1, 2),
        (2, 0), (2, 1), (2, 2)
    ))
}

extension PieceShape {
    /// Weighted pool — shape repetition controls how often each shape
    /// appears in random draws. Lines (1×N, N×1) and squares (2×2, 3×3)
    /// repeat several times each so the player gets shapes that are
    /// easy to slot in and easy to use for clears. Awkward rotations
    /// and pentominoes are rare.
    ///
    /// All three difficulty pools share the same weighting structure;
    /// higher pools only *add* shapes, never remove them.

    /// Beginner pool — single cell, lines up to 4, all small squares,
    /// small L corners. Maximally forgiving.
    static let easyPool: [PieceShape] = [
        // 1
        PieceShape.mono,
        // 1×2 (×3)
        PieceShape.line2H, PieceShape.line2H, PieceShape.line2H,
        PieceShape.line2V, PieceShape.line2V, PieceShape.line2V,
        // 1×3 (×3)
        PieceShape.line3H, PieceShape.line3H, PieceShape.line3H,
        PieceShape.line3V, PieceShape.line3V, PieceShape.line3V,
        // 1×4 (×2)
        PieceShape.line4H, PieceShape.line4H,
        PieceShape.line4V, PieceShape.line4V,
        // 2×2 (×3) — workhorse piece
        PieceShape.square2x2, PieceShape.square2x2, PieceShape.square2x2,
        // small L corner (×1 each) — for variety, not over-weighted
        PieceShape.triL_TL, PieceShape.triL_TR,
        PieceShape.triL_BL, PieceShape.triL_BR,
    ]

    /// Adds 1×5 lines, tetris-L and J (one rotation each so corner
    /// pieces aren't dominant). Unlocked at moderate scores.
    static let mediumPool: [PieceShape] = easyPool + [
        // 1×5 (×2)
        PieceShape.line5H, PieceShape.line5H,
        PieceShape.line5V, PieceShape.line5V,
        // L / J (rare — 1 of each rotation)
        PieceShape.L_r0, PieceShape.L_r1, PieceShape.L_r2, PieceShape.L_r3,
        PieceShape.J_r0, PieceShape.J_r1, PieceShape.J_r2, PieceShape.J_r3,
    ]

    /// Adds 3×3 block and the trickier T/S/Z tetrominoes + rectangles.
    /// Big L pentomino kept rare. `plus` / `u` removed per user request.
    static let hardPool: [PieceShape] = mediumPool + [
        // 3×3 (×2) — satisfying when you place it
        PieceShape.square3x3, PieceShape.square3x3,
        // T / S / Z — single rotation each
        PieceShape.T_r0, PieceShape.T_r1, PieceShape.T_r2, PieceShape.T_r3,
        PieceShape.S_r0, PieceShape.S_r1,
        PieceShape.Z_r0, PieceShape.Z_r1,
        // 2×3 / 3×2 rectangles (×1 each)
        PieceShape.rect2x3, PieceShape.rect3x2,
        // Big L — rare, one rotation each
        PieceShape.bigL_r0, PieceShape.bigL_r1, PieceShape.bigL_r2, PieceShape.bigL_r3,
    ]

    /// Catalog of every shape. Alias for `hardPool`.
    static var all: [PieceShape] { hardPool }
}
