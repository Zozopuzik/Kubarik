//
//  ClearEvent.swift
//  Kubarik
//
//  Emitted by GameState whenever a placement clears one or more lines.
//  The UI listens for this and spawns particle bursts, the "+N" score
//  popup, the praise callout, and screen shake. Carries everything the
//  view layer needs without it having to inspect the board.
//

import Foundation

struct ClearEvent: Equatable {
    let id: UUID
    let clearedCells: [GridPosition]
    let dominantColor: TileColor
    let lineCount: Int
    let combo: Int
    let scoreDelta: Int

    init(
        clearedCells: [GridPosition],
        dominantColor: TileColor,
        lineCount: Int,
        combo: Int,
        scoreDelta: Int
    ) {
        self.id = UUID()
        self.clearedCells = clearedCells
        self.dominantColor = dominantColor
        self.lineCount = lineCount
        self.combo = combo
        self.scoreDelta = scoreDelta
    }
}
