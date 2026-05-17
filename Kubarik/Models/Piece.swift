//
//  Piece.swift
//  Kubarik
//
//  A concrete game piece — a shape that has been assigned a color and is
//  ready to be placed. Pieces live in the tray (3 at a time) until the
//  player drags them onto the board.
//

import Foundation

struct Piece: Identifiable, Hashable {
    let id: UUID
    let shape: PieceShape
    let color: TileColor

    init(id: UUID = UUID(), shape: PieceShape, color: TileColor) {
        self.id = id
        self.shape = shape
        self.color = color
    }
}

extension Piece {
    /// Generates a piece using a random shape and a random color from the
    /// currently-active scheme. Caller controls when to spawn — typically
    /// when the tray empties or at the start of a game.
    static func random(
        scheme: ColorScheme = .classic,
        pool: [PieceShape] = PieceShape.all
    ) -> Piece {
        let shape = pool.randomElement() ?? PieceShape.mono
        let color = scheme.tileColors.randomElement() ?? TileColor.coral
        return Piece(shape: shape, color: color)
    }
}
