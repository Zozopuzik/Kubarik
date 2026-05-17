//
//  DragState.swift
//  Kubarik
//
//  Lightweight value type describing an in-flight piece drag — which slot
//  it came from, where the finger is in the game coordinate space, and the
//  cell on the board the piece would currently land at (nil if the position
//  is off-board or blocked).
//

import CoreGraphics

struct DragState: Equatable {
    let trayIndex: Int
    let piece: Piece
    var fingerLocation: CGPoint
    var hoverOrigin: GridPosition? = nil
}
