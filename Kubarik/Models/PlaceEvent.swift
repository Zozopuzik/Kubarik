//
//  PlaceEvent.swift
//  Kubarik
//
//  Emitted whenever a piece lands on the board. UI listens to play the
//  "settle pop" bounce animation on the freshly-placed cells.
//

import Foundation

struct PlaceEvent: Equatable {
    let id: UUID
    let placedCells: [GridPosition]
    let color: TileColor

    init(placedCells: [GridPosition], color: TileColor) {
        self.id = UUID()
        self.placedCells = placedCells
        self.color = color
    }
}
