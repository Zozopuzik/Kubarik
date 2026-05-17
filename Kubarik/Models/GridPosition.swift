//
//  GridPosition.swift
//  Kubarik
//
//  A single cell coordinate (row, col). Used for both grid cells on the
//  board and relative cell offsets that describe a piece's shape.
//

import Foundation

struct GridPosition: Hashable {
    let row: Int
    let col: Int

    func offset(by other: GridPosition) -> GridPosition {
        GridPosition(row: row + other.row, col: col + other.col)
    }
}
