//
//  BoardView.swift
//  Kubarik
//
//  Renders the 7×7 grid. Three layers of state per cell:
//  - The board's actual content (placed tile or empty slot).
//  - "Just placed" cells get a settle pop bounce.
//  - "Will-clear" rows/columns pulse brighter while the player hovers a
//    placement that would complete them — a payoff teaser.
//
//  Also draws the semi-transparent ghost overlay of the dragged piece.
//

import SwiftUI

struct BoardHoverHighlight: Equatable {
    let origin: GridPosition
    let piece: Piece
}

struct BoardView: View {
    let board: Board
    var highlight: BoardHoverHighlight? = nil
    var justPlacedCells: Set<GridPosition> = []
    var willClearRows: Set<Int> = []
    var willClearCols: Set<Int> = []
    /// Color of the piece currently hovering — used to ghost-fill empty
    /// cells in rows or columns that would clear on drop.
    var willClearColor: TileColor? = nil
    var totalWidth: CGFloat = 360
    var spacing: CGFloat = 7
    var onFrameChange: ((CGRect) -> Void)? = nil

    var cellSize: CGFloat {
        let n = CGFloat(Board.size)
        let raw = (totalWidth - spacing * (n - 1)) / n
        return max(1, raw)
    }

    var cellPitch: CGFloat { cellSize + spacing }

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: spacing) {
                ForEach(0..<Board.size, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(0..<Board.size, id: \.self) { col in
                            let pos = GridPosition(row: row, col: col)
                            BoardCellView(
                                color: board.cells[row][col],
                                size: cellSize,
                                isJustPlaced: justPlacedCells.contains(pos),
                                willClear: willClearRows.contains(row) || willClearCols.contains(col),
                                willClearColor: willClearColor
                            )
                        }
                    }
                }
            }
            .frame(width: totalWidth, height: totalWidth)
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            onFrameChange?(proxy.frame(in: .named("game")))
                        }
                        .onChange(of: proxy.frame(in: .named("game"))) { _, newValue in
                            onFrameChange?(newValue)
                        }
                }
            )

            if let highlight {
                PiecePreview(
                    piece: highlight.piece,
                    cellSize: cellSize,
                    spacing: spacing,
                    cellDepth: 0
                )
                .opacity(0.45)
                .offset(
                    x: CGFloat(highlight.origin.col) * cellPitch,
                    y: CGFloat(highlight.origin.row) * cellPitch
                )
                .allowsHitTesting(false)
            }
        }
        .padding(8)
        .background(SurfacePanel())
    }
}

#Preview {
    ZStack {
        CreamBackground()
        BoardView(board: previewBoard())
    }
}

private func previewBoard() -> Board {
    var b = Board()
    b = b.placing(Piece(shape: .square2x2, color: .coral), at: GridPosition(row: 0, col: 0))
    b = b.placing(Piece(shape: .line3H, color: .turquoise), at: GridPosition(row: 3, col: 2))
    b = b.placing(Piece(shape: .L_r0, color: .lavender), at: GridPosition(row: 5, col: 5))
    return b
}
