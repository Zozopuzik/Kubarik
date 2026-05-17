//
//  GameOverSheet.swift
//  Kubarik
//
//  Bottom sheet shown automatically when the player has no legal moves
//  left. Surfaces the final score and best-so-far, and offers a quick
//  "Play Again" / "Home" choice.
//

import SwiftUI

struct GameOverSheet: View {
    let score: Int
    let bestScore: Int
    let isNewBest: Bool

    var onPlayAgain: () -> Void = {}
    var onHome: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            Text(isNewBest ? "NEW BEST!" : "GAME OVER")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .tracking(3)
                .foregroundStyle(Palette.taglineBrown)

            Spacer().frame(height: 14)

            Text("\(score)")
                .font(.system(size: 72, weight: .heavy, design: .rounded))
                .foregroundStyle(Palette.textBrown)
                .contentTransition(.numericText(value: Double(score)))

            Text("points")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(Palette.textBrown.opacity(0.55))

            Spacer().frame(height: 18)

            bestRow

            Spacer().frame(height: 26)

            buttons

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .presentationDetents([.fraction(0.5)])
        .presentationCornerRadius(34)
        .presentationDragIndicator(.hidden)
        .interactiveDismissDisabled(true)
        .presentationBackground(Color(hex: 0xFFF3DF))
    }

    private var bestRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Palette.taglineBrown.opacity(0.7))
            Text("BEST")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Palette.textBrown.opacity(0.55))
            Text("\(bestScore)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.textBrown)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color(hex: 0x8C643C).opacity(0.06))
        )
    }

    private var buttons: some View {
        VStack(spacing: 16) {
            PlayButton(
                color: .mint,
                label: "PLAY AGAIN",
                width: 252,
                action: onPlayAgain
            )

            Button(action: onHome) {
                Text("HOME")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .tracking(2.4)
                    .foregroundStyle(Palette.textBrown.opacity(0.7))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 22)
            }
        }
    }
}

#Preview {
    Color.gray.opacity(0.3)
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            GameOverSheet(score: 142, bestScore: 320, isNewBest: false)
        }
}
