//
//  DragFollowerView.swift
//  Kubarik
//
//  The piece graphic that follows the user's finger during a drag. Drawn
//  in board-cell size (not tray-preview size) so the user sees the piece
//  at its real footprint while choosing where to drop it.
//
//  The piece is "lifted" above the finger by `liftY` points so the user's
//  hand doesn't cover the piece — standard block-puzzle convention.
//

import SwiftUI

struct DragFollowerView: View {
    let piece: Piece
    let location: CGPoint
    let cellSize: CGFloat
    let cellSpacing: CGFloat
    let liftY: CGFloat

    var body: some View {
        PiecePreview(piece: piece, cellSize: cellSize, spacing: cellSpacing)
            .position(x: location.x, y: location.y - liftY)
            .allowsHitTesting(false)
    }
}
