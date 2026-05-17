//
//  SplashView.swift
//  Kubarik
//
//  First-paint brand reveal. Three letter cubes (K / U / B) drop in from
//  above one after another, then the wordmark and SDS mark fade up. After
//  ~1.7s we hand off to ContentView's NavigationStack. Tap anywhere to
//  skip — sets the same flag immediately.
//

import SwiftUI

struct SplashView: View {
    var onComplete: () -> Void = {}

    @State private var cubesIn = [false, false, false]
    @State private var wordmarkIn = false
    @State private var taglineIn = false

    private let cubes: [(color: TileColor, letter: String, offsetX: CGFloat, top: CGFloat, rotation: Double)] = [
        (.amber, "K",  18, 230, -6),
        (.coral, "U", -16, 330,  4),
        (.mint,  "B",   8, 430, -2),
    ]

    private let cubeSize: CGFloat = 124
    private let cubeRadius: CGFloat = 34
    private let cubeDepth: CGFloat = 14

    var body: some View {
        ZStack {
            background
                .ignoresSafeArea()

            GeometryReader { proxy in
                let cx = proxy.size.width / 2

                ZStack {
                    ForEach(Array(cubes.enumerated()), id: \.offset) { index, cube in
                        cubeView(cube)
                            .position(x: cx + cube.offsetX, y: cube.top + cubeSize / 2)
                            .opacity(cubesIn[index] ? 1 : 0)
                            .offset(y: cubesIn[index] ? 0 : -580)
                    }

                    Text("KUBARIKI")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .tracking(6)
                        .foregroundStyle(Palette.textBrown)
                        .position(x: cx, y: 600)
                        .opacity(wordmarkIn ? 1 : 0)
                        .offset(y: wordmarkIn ? 0 : 10)

                    SDSMark()
                        .position(x: cx, y: proxy.size.height - 84)
                        .opacity(taglineIn ? 1 : 0)
                        .offset(y: taglineIn ? 0 : 10)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onComplete() }
        .onAppear(perform: play)
    }

    private var background: some View {
        RadialGradient(
            colors: [Color(hex: 0xFFF8EE), Color(hex: 0xFFEED8)],
            center: UnitPoint(x: 0.5, y: 0.45),
            startRadius: 50,
            endRadius: 500
        )
    }

    private func cubeView(_ cube: (color: TileColor, letter: String, offsetX: CGFloat, top: CGFloat, rotation: Double)) -> some View {
        TileView(
            color: cube.color,
            size: cubeSize,
            radius: cubeRadius,
            depth: cubeDepth,
            rotation: cube.rotation
        ) {
            Text(cube.letter)
                .font(.system(size: 80, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: cube.color.edge, radius: 0, x: 0, y: 2)
                .shadow(color: cube.color.edge, radius: 0, x: 0, y: 4)
                .shadow(color: cube.color.edge, radius: 0, x: 0, y: 6)
                .shadow(color: .black.opacity(0.22), radius: 14, x: 0, y: 10)
        }
    }

    private func play() {
        for index in cubes.indices {
            let delay = Double(index) * 0.16
            withAnimation(.spring(response: 0.52, dampingFraction: 0.62).delay(delay)) {
                cubesIn[index] = true
            }
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.9)) {
            wordmarkIn = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(1.2)) {
            taglineIn = true
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1700))
            onComplete()
        }
    }
}

#Preview {
    SplashView()
}
