import SwiftUI

/// A SwiftUI view that runs a fully interactive Minesweeper game.
///
/// Configure the view with the builder modifiers before it is placed in the view hierarchy:
///
/// ```swift
/// @State private var model = MinesweeperModel(rows: 9, columns: 9, mineCount: 10)
/// @State private var flagging = false
///
/// var body: some View {
///     MinesweeperGameView(model: $model)
///         .grid(spacing: 4, cell: MinesweeperCell.self)
///         .flaggingMode(flagging)
///         .onInput { coord, score in
///             print("Revealed (\(coord.row), \(coord.col)) — score: \(score)")
///         }
///         .onCompletion { didWin in
///             print(didWin ? "You cleared the board!" : "Boom!")
///         }
/// }
/// ```
///
/// ### Interactions
/// - **Tap** a hidden cell to reveal it. If it has zero adjacent mines the reveal flood-fills outward automatically.
///   Cells revealed by a flood-fill animate in ripple waves radiating outward from the tapped cell.
/// - **Long-press** a hidden cell to plant a flag; long-press again to remove it. Flagged cells cannot be revealed by tap.
/// - **Flagging mode** — when ``flaggingMode(_:)`` is enabled, every tap plants or removes a flag instead of
///   revealing the cell. Long-press continues to work regardless of this setting.
///
/// ### Game end
/// When the player hits a mine, all mine positions are revealed as ``MinesweeperCellState/mineRevealed``
/// and any flags on safe cells are cleared to ``MinesweeperCellState/hidden``. Unrevealed safe cells
/// remain hidden — only the mines are exposed.
///
/// ### Scoring
/// Each safely revealed cell awards one point. The cumulative score is reported through ``onInput(_:)`` after every reveal.
///
/// ### Mine placement
/// If `MinesweeperModel.mines` is empty the view generates mines on the player's first tap, ensuring that cell and
/// all its immediate neighbors are mine-free.
public struct MinesweeperGameView: View {

    // MARK: - Configuration

    @Binding var model: MinesweeperModel
    private var gridSpacing: CGFloat = 4
    private let revealStepDelay: Double = 0.05
    private var isFlagging: Bool = false

    // MARK: - Private state

    /// Incremented whenever a new reveal starts or the view disappears.
    /// Each `asyncAfter` closure captures the epoch at dispatch time and exits early if it has
    /// changed by the time it fires — preventing in-flight state mutations from interfering with
    /// a NavigationStack pop transition.
    @State private var revealEpoch: Int = 0

    /// Guards the one-shot auto-tap so it fires only once on first load,
    /// not on resume or background return.
    @State private var hasAutoTapped: Bool = false

    /// When `true` the next player tap is treated as mine-safe: the game will not end even
    /// if the tapped cell contains a mine. Cleared immediately after one tap.
    @State private var isHintModeActive: Bool = false

    private var cellFactory: (_ row: Int, _ col: Int, _ state: MinesweeperCellState) -> AnyView =
    { row, col, state in
        AnyView(MinesweeperCell(row: row, column: col, state: state))
    }

    private var hintTrigger: Binding<Int>? = nil
    private var onInputCallback: ((_ coord: MinesweeperCoord, _ score: Int) -> Void)? = nil
    private var onCompletionCallback: ((_ didWin: Bool) -> Void)? = nil

    // MARK: - Init

    /// Creates a new game view with the given model binding.
    ///
    /// Apply `.grid(spacing:cell:)`, `.onInput(_:)`, and `.onCompletion(_:)` modifiers before
    /// inserting the view into the hierarchy.
    ///
    /// - Parameter model: A binding to the ``MinesweeperModel`` that defines the grid dimensions,
    ///   mine count, and live game state. All state changes are written back through this binding.
    public init(model: Binding<MinesweeperModel>) {
        self._model = model
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: gridSpacing) {
            ForEach(0..<model.rows, id: \.self) { row in
                HStack(spacing: gridSpacing) {
                    ForEach(0..<model.columns, id: \.self) { col in
                        let coord = MinesweeperCoord(row: row, col: col)
                        cellFactory(row, col, model.cellStates[row][col])
                            .onTapGesture { handleTap(at: coord) }
                            .onLongPressGesture { handleLongPress(at: coord) }
                    }
                }
            }
        }
        .task {
            guard !hasAutoTapped, model.score == 0 else { return }
            let coord = bestAutoTapCoord()
            hasAutoTapped = true
            try? await Task.sleep(for: .seconds(0.25))
            handleTap(at: coord)
        }
        .onChange(of: hintTrigger?.wrappedValue ?? 0) { oldValue, newValue in
            guard newValue > oldValue, newValue > 0 else { return }
            guard !model.isGameOver, !model.activeMines.isEmpty else { return }
            for row in 0..<model.rows {
                for col in 0..<model.columns {
                    if case .hidden = model.cellStates[row][col] {
                        model.cellStates[row][col] = .hintEligible
                    }
                }
            }
            isHintModeActive = true
        }
        .onDisappear { revealEpoch += 1 }
    }

    // MARK: - Modifiers

    /// Sets the cell spacing and registers a custom cell type for the grid.
    ///
    /// - Parameters:
    ///   - spacing: Points of space between adjacent cells.
    ///   - cell: A type conforming to ``MinesweeperCellProtocol`` used to render each grid cell.
    public func grid<T: MinesweeperCellProtocol>(spacing: CGFloat, cell: T.Type) -> Self {
        var copy = self
        copy.gridSpacing = spacing
        copy.cellFactory = { row, col, state in AnyView(T(row: row, column: col, state: state)) }
        return copy
    }

    /// Registers a handler that fires each time a safe cell is revealed.
    ///
    /// When a single tap triggers a flood-fill, the handler is called once per revealed cell in
    /// BFS order, each time with the updated cumulative `score`.
    ///
    /// - Parameter handler: Receives the revealed cell's coordinate and the current total score.
    public func onInput(_ handler: @escaping (_ coord: MinesweeperCoord, _ score: Int) -> Void) -> Self {
        var copy = self
        copy.onInputCallback = handler
        return copy
    }

    /// Registers a handler that fires once when the game ends.
    ///
    /// - Parameter handler: Receives `true` when all safe cells have been revealed (win),
    ///   or `false` when the player tapped a mine (loss).
    public func onCompletion(_ handler: @escaping (_ didWin: Bool) -> Void) -> Self {
        var copy = self
        copy.onCompletionCallback = handler
        return copy
    }

    /// Enables or disables flagging mode.
    ///
    /// When `isOn` is `true`, tapping any cell plants or removes a flag instead of revealing it —
    /// identical to a long-press. Long-press continues to work regardless of this setting.
    ///
    /// ```swift
    /// @State private var flagging = false
    ///
    /// MinesweeperGameView(model: $model)
    ///     .flaggingMode(flagging)
    /// ```
    ///
    /// - Parameter isOn: When `true`, taps act as flags.
    public func flaggingMode(_ isOn: Bool) -> Self {
        var copy = self
        copy.isFlagging = isOn
        return copy
    }

    /// Connects an external hint counter to the view.
    ///
    /// Each time the binding's value **increases**, hint mode is activated: the board enters a
    /// protected state where the player can tap any cell freely. If a mine is tapped during
    /// hint mode the game does **not** end — the mine is shown but play continues. Hint mode ends once
    /// the player taps any hidden cell. Has no effect when mines have not yet been placed
    /// (game hasn't started) or when the game is over.
    ///
    /// ```swift
    /// @State private var hintCount = 0
    ///
    /// MinesweeperGameView(model: $model)
    ///     .hint(trigger: $hintCount)
    ///
    /// Button("Hint") { hintCount += 1 }
    /// ```
    ///
    /// - Parameter trigger: A binding to an integer counter owned by the parent. The view reads
    ///   this value reactively; only increases activate hint mode.
    public func hint(trigger: Binding<Int>) -> Self {
        var copy = self
        copy.hintTrigger = trigger
        return copy
    }

    // MARK: - Helpers

    /// Returns the best cell to auto-tap on game load, maximising the number of cells revealed.
    ///
    /// **Strategy:**
    /// 1. Scan interior cells first (not on any border row/column) — all 8 neighbours are
    ///    available, so a zero-adjacency cell here produces the largest possible flood-fill.
    /// 2. If the best interior result has zero adjacency, return it immediately.
    /// 3. Otherwise all interior cells would reveal only 1 cell. Widen the search to border
    ///    and corner cells — a zero-adjacency border cell still reveals multiple cells via
    ///    flood-fill, which is better than revealing a single interior cell with adjacency > 0.
    /// 4. Among all candidates, pick the lowest-adjacency cell, breaking ties by Manhattan
    ///    distance to the grid centre.
    ///
    /// For auto-generated games (mines not yet placed) the centre is returned directly — the
    /// first-tap safety zone guarantees the centre and all 8 neighbours are mine-free.
    private func bestAutoTapCoord() -> MinesweeperCoord {
        let centerRow = model.rows / 2
        let centerCol = model.columns / 2
        let center    = MinesweeperCoord(row: centerRow, col: centerCol)

        guard !model.activeMines.isEmpty else { return center }

        func isBetter(adj: Int, dist: Int, thanAdj bestAdj: Int, dist bestDist: Int) -> Bool {
            adj < bestAdj || (adj == bestAdj && dist < bestDist)
        }

        // Pass 1 — interior cells only.
        var bestCoord = center
        var bestAdj   = Int.max
        var bestDist  = Int.max

        for r in 1..<(model.rows - 1) {
            for c in 1..<(model.columns - 1) {
                let candidate = MinesweeperCoord(row: r, col: c)
                guard !model.activeMines.contains(candidate) else { continue }
                let adj  = model.adjacentMineCount(for: candidate, in: model.activeMines)
                let dist = abs(r - centerRow) + abs(c - centerCol)
                if isBetter(adj: adj, dist: dist, thanAdj: bestAdj, dist: bestDist) {
                    bestAdj = adj; bestDist = dist; bestCoord = candidate
                }
            }
        }

        // If an interior zero-adjacency cell was found, nothing beats it.
        if bestAdj == 0 { return bestCoord }

        // Pass 2 — all interior cells would reveal only 1 cell; widen to borders/corners.
        for r in 0..<model.rows {
            for c in 0..<model.columns {
                let isInterior = r > 0 && r < model.rows - 1 && c > 0 && c < model.columns - 1
                guard !isInterior else { continue }   // already scanned above
                let candidate = MinesweeperCoord(row: r, col: c)
                guard !model.activeMines.contains(candidate) else { continue }
                let adj  = model.adjacentMineCount(for: candidate, in: model.activeMines)
                let dist = abs(r - centerRow) + abs(c - centerCol)
                if isBetter(adj: adj, dist: dist, thanAdj: bestAdj, dist: bestDist) {
                    bestAdj = adj; bestDist = dist; bestCoord = candidate
                }
            }
        }

        return bestCoord
    }

    private func handleTap(at coord: MinesweeperCoord) {
        guard !model.isGameOver else { return }

        if isFlagging {
            handleLongPress(at: coord)
            return
        }

        switch model.cellStates[coord.row][coord.col] {
        case .hidden, .hintEligible: break
        default: return
        }

        // Auto-generate mines on first tap, guaranteeing the tapped cell + its neighbors are safe
        if model.activeMines.isEmpty && model.mines.isEmpty {
            let safeZone = Set([coord] + model.neighbors(of: coord))
            model.activeMines = model.generateMines(avoiding: safeZone)
        }

        if isHintModeActive {
            isHintModeActive = false
            // Revert all hint-eligible cells back to hidden before handling the tap
            for row in 0..<model.rows {
                for col in 0..<model.columns {
                    if case .hintEligible = model.cellStates[row][col] {
                        model.cellStates[row][col] = .hidden
                    }
                }
            }
            if model.activeMines.contains(coord) {
                model.cellStates[coord.row][coord.col] = .mineRevealed
            } else {
                revealCells(from: coord)
            }
            return
        }

        if model.activeMines.contains(coord) {
            triggerGameOver(explodedAt: coord)
        } else {
            revealCells(from: coord)
        }
    }

    private func handleLongPress(at coord: MinesweeperCoord) {
        guard !model.isGameOver else { return }
        switch model.cellStates[coord.row][coord.col] {
        case .hidden:  model.cellStates[coord.row][coord.col] = .flagged
        case .flagged: model.cellStates[coord.row][coord.col] = .hidden
        default:       break
        }
    }

    /// BFS flood-fill reveal: auto-expands through cells with zero adjacent mines.
    /// Cells are grouped by BFS distance from `start` and revealed in staggered waves,
    /// producing a ripple animation outward from the tapped cell.
    private func revealCells(from start: MinesweeperCoord) {
        // Cancel any closures still in flight from a previous reveal (e.g. rapid successive taps).
        revealEpoch += 1

        // Pass 1 — collect cells grouped by BFS distance (level), no state mutations yet.
        var levels: [[(coord: MinesweeperCoord, adjCount: Int)]] = []
        var visited: Set<MinesweeperCoord> = []
        var frontier: [MinesweeperCoord] = [start]

        while !frontier.isEmpty {
            var levelCells: [(coord: MinesweeperCoord, adjCount: Int)] = []
            var nextFrontier: [MinesweeperCoord] = []

            for coord in frontier {
                guard !visited.contains(coord) else { continue }
                switch model.cellStates[coord.row][coord.col] {
                case .hidden, .flagged: break   // reveal regardless — flags are cleared on reveal
                default: continue
                }
                visited.insert(coord)

                let adjCount = model.adjacentMineCount(for: coord, in: model.activeMines)
                levelCells.append((coord, adjCount))

                if adjCount == 0 {
                    for neighbor in model.neighbors(of: coord) {
                        guard !visited.contains(neighbor) else { continue }
                        switch model.cellStates[neighbor.row][neighbor.col] {
                        case .hidden, .flagged: nextFrontier.append(neighbor)
                        default: break
                        }
                    }
                }
            }

            if !levelCells.isEmpty { levels.append(levelCells) }
            frontier = nextFrontier
        }

        // Pass 2 — apply state updates staggered by distance (50 ms per BFS level).
        let epoch = revealEpoch
        for (i, levelCells) in levels.enumerated() {
            let isLast = i == levels.count - 1
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * revealStepDelay) {
                // If the epoch changed (view dismissed or a newer reveal started), discard silently.
                guard revealEpoch == epoch else { return }
                for (coord, adjCount) in levelCells {
                    model.cellStates[coord.row][coord.col] = .revealed(adjacentMines: adjCount)
                    model.score += 1
                    onInputCallback?(coord, model.score)
                }
                if isLast { checkWin() }
            }
        }
    }

    private func triggerGameOver(explodedAt coord: MinesweeperCoord) {
        model.cellStates[coord.row][coord.col] = .exploded
        revealEndState(revealMines: true)
        model.isGameOver = true
        model.didWin = false
        onCompletionCallback?(false)
    }

    private func checkWin() {
        guard model.score >= model.totalSafe else { return }
        revealEndState(revealMines: false)
        model.isGameOver = true
        model.didWin = true
        onCompletionCallback?(true)
    }

    /// Called at game end. Shows mine positions and removes all flags, leaving unrevealed safe
    /// cells untouched.
    ///
    /// - Parameter revealMines: When `true` (loss), hidden/flagged mines → `.mineRevealed`.
    ///   When `false` (win), mines stay in their current state — correct flags on mines remain.
    /// - Flags on safe cells are always cleared to `.hidden`.
    private func revealEndState(revealMines: Bool) {
        // Pass 1 — reveal mine positions (loss only).
        if revealMines {
            for mine in model.activeMines {
                switch model.cellStates[mine.row][mine.col] {
                case .hidden, .flagged, .hintEligible:
                    model.cellStates[mine.row][mine.col] = .mineRevealed
                default:
                    break
                }
            }
        }
        // Pass 2 — clear incorrect flags on safe cells back to hidden.
        for row in 0..<model.rows {
            for col in 0..<model.columns {
                guard case .flagged = model.cellStates[row][col] else { continue }
                if !model.activeMines.contains(MinesweeperCoord(row: row, col: col)) {
                    model.cellStates[row][col] = .hidden
                }
            }
        }
    }
}
