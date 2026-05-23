//
//  GameView.swift
//  Kubarik
//
//  Top-level game screen. Owns the GameState plus a transient effects
//  layer: praise callouts, particle bursts, "+N" floats, settle-pop
//  tracking, will-clear glow prediction, and screen shake.
//
//  Effect events arrive via `game.lastPlaceEvent` and `game.lastClearEvent`
//  observed with `.onChange` — the view spawns ephemeral state and
//  schedules its own cleanup via Tasks.
//

import SwiftUI

struct GameView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var auth
    @Environment(AudioPlayer.self) private var audio
    @State private var game = GameState()
    @State private var dragState: DragState? = nil
    @State private var boardFrame: CGRect = .zero

    // Effects state
    @State private var shake = ScreenShakeDriver()
    @State private var haptics = HapticEngine()
    @Environment(PreferencesStore.self) private var prefs
    @State private var praise: PraiseInstance? = nil
    @State private var particles: [Particle] = []
    @State private var justPlacedCells: Set<GridPosition> = []

    /// "+N" delta that drifts up from under the SCORE block after each clear.
    @State private var headerScoreDelta: Int? = nil
    @State private var headerDeltaOpacity: Double = 0
    @State private var headerDeltaOffsetY: CGFloat = 0
    @State private var headerDeltaColor: TileColor = .coral

    // Cached will-clear prediction — recomputed only when the hovered
    // origin changes, not on every body redraw.
    @State private var willClearRows: Set<Int> = []
    @State private var willClearCols: Set<Int> = []
    @State private var hoverOriginKey: String? = nil

    // Tunables
    private let dragLiftY: CGFloat = 80
    private let boardSidePadding: CGFloat = 16
    private let boardSpacing: CGFloat = 7

    var body: some View {
        GeometryReader { proxy in
            let boardWidth = max(0, proxy.size.width - boardSidePadding * 2)

            ZStack(alignment: .top) {
                CreamBackground()

                shakeWrapper {
                    VStack(spacing: 0) {
                        header
                            .padding(.horizontal, 20)
                            .padding(.top, 12)

                        Spacer(minLength: 28)

                        BoardView(
                            board: game.board,
                            highlight: hoverHighlight,
                            justPlacedCells: justPlacedCells,
                            willClearRows: willClearRows,
                            willClearCols: willClearCols,
                            willClearColor: dragState?.piece.color,
                            totalWidth: boardWidth,
                            spacing: boardSpacing,
                            onFrameChange: { boardFrame = $0 }
                        )

                        Spacer().frame(height: 28)

                        TrayView(
                            pieces: game.tray,
                            draggingIndex: dragState?.trayIndex,
                            panelWidth: boardWidth + 16,
                            onPickup: handlePickup,
                            onDragMove: handleDragMove,
                            onDragEnd: handleDragEnd
                        )

                        Spacer(minLength: 24)
                    }
                }

                // Effects overlay — particles, "+N", praise
                effectsLayer
                    .allowsHitTesting(false)

                if let drag = dragState {
                    DragFollowerView(
                        piece: drag.piece,
                        location: drag.fingerLocation,
                        cellSize: cellSize(for: boardWidth),
                        cellSpacing: boardSpacing,
                        liftY: dragLiftY
                    )
                }
            }
            .coordinateSpace(.named("game"))
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: game.hapticEvent) { _, pulse in
            if let pulse { haptics.play(pulse) }
        }
        .onAppear {
            haptics.level = prefs.hapticLevel
            audio.playBackgroundLoop("Marble Cloud Garden")
        }
        .onChange(of: prefs.hapticLevel) { _, new in
            haptics.level = new
        }
        .onChange(of: game.isGameOver) { _, isOver in
            if isOver {
                // Log the game to the cloud + refresh totals.
                Task { await auth.recordGameOver(score: game.score, linesCleared: 0) }
                // Swap the music to the sad/contemplative track.
                audio.playBackgroundLoop("Lost Star")
            } else {
                // Player tapped Play Again — back to the game loop track.
                audio.playBackgroundLoop("Marble Cloud Garden")
            }
        }
        .onChange(of: game.lastPlaceEvent) { _, new in
            if let event = new { handlePlaceEvent(event) }
        }
        .onChange(of: game.lastClearEvent) { _, new in
            if let event = new { handleClearEvent(event) }
        }
        .sheet(isPresented: gameOverBinding) {
            GameOverSheet(
                score: game.score,
                bestScore: game.bestScore,
                isNewBest: game.justBeatBest,
                onPlayAgain: { game.restart() },
                onHome: handleGoHome
            )
        }
    }

    /// Closes the game-over sheet first, then pops back to welcome once
    /// the dismiss animation has played. Without the wait the navigation
    /// pop and the sheet dismiss overlap and the welcome screen flashes
    /// in behind a half-visible modal.
    private func handleGoHome() {
        game.clearGameOver()
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(280))
            dismiss()
        }
    }

    private func shakeWrapper<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .screenShake(shake)
    }

    private var gameOverBinding: Binding<Bool> {
        Binding(
            get: { game.isGameOver },
            set: { _ in }
        )
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            scoreBlock(label: "BEST", value: game.bestScore, accent: false)

            Spacer()

            scoreBlock(label: "SCORE", value: game.score, accent: true)

            Spacer()

            IconButton(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .bold))
            }
        }
    }

    private func scoreBlock(label: String, value: Int, accent: Bool) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Palette.textBrown.opacity(0.55))
            Text("\(value)")
                .font(.system(size: accent ? 30 : 22, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.textBrown)
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(value)))
                .scaleEffect(accent ? scoreBounceScale : 1.0)
                .animation(.spring(response: 0.18, dampingFraction: 0.55), value: value)
                .overlay(alignment: .bottom) {
                    if accent, let delta = headerScoreDelta {
                        Text("+\(delta)")
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .foregroundStyle(Palette.textBrown)
                            .shadow(color: headerDeltaColor.edge.opacity(0.45), radius: 0, x: 0, y: 1)
                            .monospacedDigit()
                            .opacity(headerDeltaOpacity)
                            .offset(y: headerDeltaOffsetY)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    /// Computed scale that briefly bounces when the score increases.
    @State private var scoreBounceScale: CGFloat = 1.0

    // MARK: - Effects layer

    private var effectsLayer: some View {
        ZStack {
            ForEach(particles) { particle in
                ParticleView(particle: particle)
            }

            if let praise {
                PraiseFlash(word: praise.word, tier: praise.tier)
                    .id(praise.id)
                    .position(x: boardFrame.midX, y: boardFrame.midY - 20)
            }
        }
    }

    // MARK: - Place / Clear handlers

    private func handlePlaceEvent(_ event: PlaceEvent) {
        let cells = Set(event.placedCells)
        justPlacedCells.formUnion(cells)

        // Score bounce — subtle
        withAnimation(.spring(response: 0.14, dampingFraction: 0.55)) {
            scoreBounceScale = 1.06
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(140))
            withAnimation(.spring(response: 0.20, dampingFraction: 0.75)) {
                scoreBounceScale = 1.0
            }
        }

        // Auto-clear settle flag after pop completes
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(340))
            justPlacedCells.subtract(cells)
        }
    }

    private func handleClearEvent(_ event: ClearEvent) {
        // 1. Spawn particles at each cleared cell's screen position
        var newParticles: [Particle] = []
        for cell in event.clearedCells {
            let point = cellCenterInGameSpace(cell)
            newParticles.append(contentsOf: Particle.burst(at: point, color: event.dominantColor, count: 7))
        }
        particles.append(contentsOf: newParticles)

        let particleIds = Set(newParticles.map { $0.id })
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1200))
            particles.removeAll { particleIds.contains($0.id) }
        }

        // 2. "+N" floats up from under the SCORE block in the header
        triggerHeaderDelta(event.scoreDelta, color: event.dominantColor)

        // 3. Praise callout
        let tier = PraiseTier.evaluate(lineCount: event.lineCount, comboChain: event.combo)
        let p = PraiseInstance(word: tier.randomWord, tier: tier)
        praise = p
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1200))
            if praise?.id == p.id { praise = nil }
        }

        // 4. Screen shake — bigger as it escalates
        let intensity = min(event.lineCount + (event.combo >= 2 ? 1 : 0), 4)
        shake.trigger(intensity: intensity)
    }

    /// Pops a "+N" right under the SCORE value and drifts it up while
    /// fading. Self-cancels — calling it again mid-flight resets to a
    /// fresh entrance so consecutive combos stay readable.
    private func triggerHeaderDelta(_ delta: Int, color: TileColor) {
        headerScoreDelta = delta
        headerDeltaColor = color
        headerDeltaOffsetY = 44
        headerDeltaOpacity = 0
        withAnimation(.spring(response: 0.24, dampingFraction: 0.72)) {
            headerDeltaOffsetY = 52
            headerDeltaOpacity = 1
        }
        withAnimation(.easeIn(duration: 0.95).delay(1.05)) {
            headerDeltaOffsetY = 22
            headerDeltaOpacity = 0
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(2100))
            headerScoreDelta = nil
        }
    }

    private func cellCenterInGameSpace(_ pos: GridPosition) -> CGPoint {
        let pitch = cellSize(for: boardFrame.width) + boardSpacing
        return CGPoint(
            x: boardFrame.minX + CGFloat(pos.col) * pitch + cellSize(for: boardFrame.width) / 2,
            y: boardFrame.minY + CGFloat(pos.row) * pitch + cellSize(for: boardFrame.width) / 2
        )
    }

    // MARK: - Will-clear prediction

    /// Recompute the will-clear hint only when the hover cell changes, so
    /// dragging your finger within the same target cell doesn't pay for
    /// 49 cells of redraw on every pixel of finger movement.
    private func refreshWillClearPrediction() {
        guard let state = dragState, let origin = state.hoverOrigin else {
            if hoverOriginKey != nil {
                hoverOriginKey = nil
                willClearRows = []
                willClearCols = []
            }
            return
        }
        let key = "\(state.piece.id.uuidString)#\(origin.row),\(origin.col)"
        guard key != hoverOriginKey else { return }
        hoverOriginKey = key

        let test = game.board.placing(state.piece, at: origin)
        let full = test.fullLines()
        willClearRows = Set(full.rows)
        willClearCols = Set(full.cols)
    }

    // MARK: - Drag handlers

    private func handlePickup(trayIndex: Int, piece: Piece, fingerLocation: CGPoint) {
        var state = DragState(
            trayIndex: trayIndex,
            piece: piece,
            fingerLocation: fingerLocation
        )
        state.hoverOrigin = computeHoverOrigin(for: piece, fingerLocation: fingerLocation)
        dragState = state
        refreshWillClearPrediction()
        game.notifyPickup()
    }

    private func handleDragMove(fingerLocation: CGPoint) {
        guard var state = dragState else { return }
        state.fingerLocation = fingerLocation
        state.hoverOrigin = computeHoverOrigin(for: state.piece, fingerLocation: fingerLocation)
        dragState = state
        refreshWillClearPrediction()
    }

    private func handleDragEnd() {
        defer {
            dragState = nil
            refreshWillClearPrediction()
        }
        guard let state = dragState, let origin = state.hoverOrigin else { return }
        game.place(trayIndex: state.trayIndex, at: origin)
    }

    // MARK: - Geometry helpers

    private func cellSize(for boardWidth: CGFloat) -> CGFloat {
        let n = CGFloat(Board.size)
        return max(1, (boardWidth - boardSpacing * (n - 1)) / n)
    }

    private var hoverHighlight: BoardHoverHighlight? {
        guard let state = dragState, let origin = state.hoverOrigin else { return nil }
        return BoardHoverHighlight(origin: origin, piece: state.piece)
    }

    private func computeHoverOrigin(for piece: Piece, fingerLocation: CGPoint) -> GridPosition? {
        guard boardFrame.width > 0 else { return nil }

        let cell = cellSize(for: boardFrame.width)
        let pitch = cell + boardSpacing

        let pieceWidth = CGFloat(piece.shape.width) * cell
            + CGFloat(max(0, piece.shape.width - 1)) * boardSpacing
        let pieceHeight = CGFloat(piece.shape.height) * cell
            + CGFloat(max(0, piece.shape.height - 1)) * boardSpacing

        let centerX = fingerLocation.x
        let centerY = fingerLocation.y - dragLiftY

        let pieceTopLeftX = centerX - boardFrame.minX - pieceWidth / 2
        let pieceTopLeftY = centerY - boardFrame.minY - pieceHeight / 2

        let col = Int((pieceTopLeftX / pitch).rounded())
        let row = Int((pieceTopLeftY / pitch).rounded())
        let primary = GridPosition(row: row, col: col)

        return nearestValidOrigin(for: piece, near: primary)
    }

    /// Magnetic snap: if the exact target cell can't host the piece, try
    /// neighboring cells within a small radius and pick the closest one
    /// that works. Makes the game much friendlier on a touch screen.
    private func nearestValidOrigin(for piece: Piece, near target: GridPosition) -> GridPosition? {
        if game.board.canPlace(piece, at: target) {
            return target
        }

        // Search outward in expanding "rings" — radius 1 first (closest
        // neighbors), then radius 2 if nothing fit nearby. Within each
        // radius, sort by Manhattan distance so the snap feels predictable.
        for radius in 1...2 {
            var ringCandidates: [GridPosition] = []
            for dr in -radius...radius {
                for dc in -radius...radius {
                    if max(abs(dr), abs(dc)) != radius { continue }
                    ringCandidates.append(
                        GridPosition(row: target.row + dr, col: target.col + dc)
                    )
                }
            }
            ringCandidates.sort {
                (abs($0.row - target.row) + abs($0.col - target.col))
                    < (abs($1.row - target.row) + abs($1.col - target.col))
            }
            for candidate in ringCandidates {
                if game.board.canPlace(piece, at: candidate) {
                    return candidate
                }
            }
        }
        return nil
    }
}

// MARK: - Praise instance helper

private struct PraiseInstance: Identifiable, Equatable {
    let id = UUID()
    let word: String
    let tier: PraiseTier
}

#Preview {
    NavigationStack {
        GameView()
    }
    .environment(AuthManager())
    .environment(AudioPlayer())
    .environment(PreferencesStore())
}
