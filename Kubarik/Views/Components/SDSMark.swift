//
//  SDSMark.swift
//  Kubarik
//
//  "BY SDS" footer mark — small diagonally-split square + tracked label.
//

import SwiftUI

struct SDSMark: View {
    var tint: Color = Palette.sdsMarkTint

    var body: some View {
        HStack(spacing: 6) {
            DiagonalSquare()
                .frame(width: 14, height: 14)

            Text("BY SDS")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .tracking(1.6)
                .foregroundStyle(tint)
        }
    }
}

private struct DiagonalSquare: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(hex: 0xFFC560))
            DiagonalHalf()
                .fill(Color(hex: 0xFF7864))
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
    }
}

private struct DiagonalHalf: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

#Preview {
    ZStack {
        CreamBackground()
        SDSMark()
    }
}
