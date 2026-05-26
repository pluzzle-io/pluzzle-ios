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

    private var cellFactory: (_ row: Int, _ col: Int, _ state: MinesweeperCellState) -> AnyView =
    { row, col, state in
        AnyView(MinesweeperCell(row: row, column: col, state: state))
    }

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

    // MARK: - Helpers

    /// Returns the best cell to auto-tap on game load — the non-mine cell with the fewest
    /// adjacent mines (0 triggers the largest flood-fill reveal).
    ///
    /// Priority:
    /// 1. `model.startingCoord` — pre-computed zero-adjacency cell from `init(grid:)`.
    /// 2. Scan all non-mine cells in `activeMines` and pick the one with minimum adjacency.
    /// 3. Centre of the grid — for auto-generated games where mines aren't placed yet;
    ///    the first-tap safety zone guarantees the centre and its 8 neighbours are mine-free,
    ///    so adjacency will be 0 after mine generation.
    private func bestAutoTapCoord() -> MinesweeperCoord {
        if let coord = model.startingCoord { return coord }

        if !model.activeMines.isEmpty {
            var best = MinesweeperCoord(row: model.rows / 2, col: model.columns / 2)
            var bestAdjacency = Int.max
            outer: for r in 0..<model.rows {
                for c in 0..<model.columns {
                    let candidate = MinesweeperCoord(row: r, col: c)
                    guard !model.activeMines.contains(candidate) else { continue }
                    let adj = model.adjacentMineCount(for: candidate, in: model.activeMines)
                    if adj < bestAdjacency {
                        bestAdjacency = adj
                        best = candidate
                        if adj == 0 { break outer } // can't do better than zero
                    }
                }
            }
            return best
        }

        // Mines not yet placed — centre maximises flood-fill potential after safe generation.
        return MinesweeperCoord(row: model.rows / 2, col: model.columns / 2)
    }

    private func handleTap(at coord: MinesweeperCoord) {
        guard !model.isGameOver else { return }

        if isFlagging {
            handleLongPress(at: coord)
            return
        }

        guard case .hidden = model.cellStates[coord.row][coord.col] else { return }

        // Auto-generate mines on first tap, guaranteeing the tapped cell + its neighbors are safe
        if model.activeMines.isEmpty && model.mines.isEmpty {
            let safeZone = Set([coord] + model.neighbors(of: coord))
            model.activeMines = model.generateMines(avoiding: safeZone)
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
                case .hidden, .flagged:
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
