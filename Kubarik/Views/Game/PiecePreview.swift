//
//  PiecePreview.swift
//  Kubarik
//
//  Renders a piece by drawing one TileView per cell, laid out using each
//  cell's (row, col) offset from the piece's top-left anchor. The whole
//  preview has a known bounding-box size so it can be slotted into the
//  tray or used as a drag-follower.
//

import SwiftUI

struct PiecePreview: View {
    let piece: Piece
    var cellSize: CGFloat = 28
    var spacing: CGFloat = 4
    /// Optional override for tile edge depth. Pass `0` to render flat
    /// (used in the tray and board-hover overlay so horizontal and
    /// vertical gaps between cells are visually identical). Leave `nil`
    /// to use TileView's default 3D edge (used by the drag follower).
    var cellDepth: CGFloat? = nil

    private var totalWidth: CGFloat {
        CGFloat(piece.shape.width) * cellSize
            + CGFloat(max(0, piece.shape.width - 1)) * spacing
    }

    private var totalHeight: CGFloat {
        CGFloat(piece.shape.height) * cellSize
            + CGFloat(max(0, piece.shape.height - 1)) * spacing
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
                .frame(width: totalWidth, height: totalHeight)

            ForEach(piece.shape.cells, id: \.self) { cell in
                TileView(
                    color: piece.color,
                    size: cellSize,
                    depth: cellDepth,
                    cast: false
                )
                .position(
                    x: CGFloat(cell.col) * (cellSize + spacing) + cellSize / 2,
                    y: CGFloat(cell.row) * (cellSize + spacing) + cellSize / 2
                )
            }
        }
        .frame(width: totalWidth, height: totalHeight)
    }
}

#Preview {
    ZStack {
        CreamBackground()
        VStack(spacing: 20) {
            PiecePreview(piece: Piece(shape: .square2x2, color: .coral))
            PiecePreview(piece: Piece(shape: .T_r0, color: .lavender))
            PiecePreview(piece: Piece(shape: .plus, color: .mint))
            PiecePreview(piece: Piece(shape: .line5H, color: .amber))
            PiecePreview(piece: Piece(shape: .square3x3, color: .cornflower))
        }
    }
}
