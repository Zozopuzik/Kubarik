//
//  TrayView.swift
//  Kubarik
//
//  The three-piece tray. One shared SurfacePanel hosts all three slots —
//  the tray reads as a single physical object, not three separate cards.
//  Each piece auto-fits its slot: the cell size is computed from the
//  piece's bounding box so 5-wide lines and 3×3 squares no longer
//  overflow.
//

import SwiftUI

struct TrayView: View {
    let pieces: [Piece?]
    var draggingIndex: Int? = nil

    /// Width of the entire tray panel.
    var panelWidth: CGFloat = 360

    /// Vertical height of the tray panel itself (includes its 3D edge).
    var panelHeight: CGFloat = 132

    /// Horizontal padding inside the panel before the first / after the
    /// last slot.
    var horizontalInset: CGFloat = 14

    /// Spacing between adjacent slots.
    var slotSpacing: CGFloat = 8

    /// Largest cell size a tray thumbnail will use, regardless of piece
    /// size. Keeps very small pieces (like 1×1) from rendering huge.
    var maxCellSize: CGFloat = 26

    var onPickup: (_ trayIndex: Int, _ piece: Piece, _ fingerLocation: CGPoint) -> Void = { _, _, _ in }
    var onDragMove: (_ fingerLocation: CGPoint) -> Void = { _ in }
    var onDragEnd: () -> Void = {}

    private var slotWidth: CGFloat {
        max(1, (panelWidth - horizontalInset * 2 - slotSpacing * 2) / 3)
    }

    private var slotHeight: CGFloat {
        max(1, panelHeight - 16)
    }

    var body: some View {
        ZStack {
            SurfacePanel()
                .frame(width: panelWidth, height: panelHeight)

            HStack(spacing: slotSpacing) {
                ForEach(0..<3, id: \.self) { index in
                    slot(at: index)
                }
            }
            .padding(.horizontal, horizontalInset)
        }
        .frame(width: panelWidth, height: panelHeight)
    }

    private func slot(at index: Int) -> some View {
        // Structure is identical for empty / dragging / occupied so the
        // view tree never collapses while a drag is in flight — that
        // collapse is what was killing the in-flight gesture session and
        // making the picked-up piece "freeze" until a second tap.
        ZStack {
            Color.clear
            slotPiece(at: index)
        }
        .frame(width: slotWidth, height: slotHeight)
        .contentShape(Rectangle())
        // High priority so the system back-swipe recognizer doesn't
        // win the first frame and stall the first drag of the session.
        .highPriorityGesture(dragGesture(at: index))
    }

    @ViewBuilder
    private func slotPiece(at index: Int) -> some View {
        if let piece = pieces[index] {
            trayThumb(for: piece, maxSize: CGSize(width: slotWidth - 12, height: slotHeight - 12))
                .opacity(draggingIndex == index ? 0 : 1)
        }
    }

    /// Renders a piece scaled to fit `maxSize`. cellSize is the smallest
    /// dimension that makes the piece's bounding box fit, capped at
    /// `maxCellSize`. Spacing scales down for very tight fits so big
    /// pieces don't get crushed.
    private func trayThumb(for piece: Piece, maxSize: CGSize) -> some View {
        let spacing: CGFloat = 3
        let cols = CGFloat(piece.shape.width)
        let rows = CGFloat(piece.shape.height)
        let widthLimit = (maxSize.width - spacing * max(0, cols - 1)) / cols
        let heightLimit = (maxSize.height - spacing * max(0, rows - 1)) / rows
        let cellSize = max(1, min(maxCellSize, widthLimit, heightLimit))

        return PiecePreview(
            piece: piece,
            cellSize: cellSize,
            spacing: spacing,
            cellDepth: 0
        )
    }

    private func dragGesture(at index: Int) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("game"))
            .onChanged { value in
                guard let piece = pieces[index] else { return }
                if draggingIndex == index {
                    onDragMove(value.location)
                } else {
                    onPickup(index, piece, value.location)
                }
            }
            .onEnded { _ in
                guard draggingIndex == index else { return }
                onDragEnd()
            }
    }
}

#Preview {
    ZStack {
        CreamBackground()
        TrayView(pieces: [
            Piece(shape: .line5H, color: .lavender),
            Piece(shape: .square3x3, color: .mint),
            Piece(shape: .T_r0, color: .coral),
        ])
        .padding(.horizontal, 16)
    }
}
