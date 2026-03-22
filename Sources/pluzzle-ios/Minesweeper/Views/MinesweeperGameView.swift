import SwiftUI

/// A SwiftUI view that runs a fully interactive Minesweeper game.
///
/// Configure the view with the builder modifiers before it is placed in the view hierarchy:
///
/// ```swift
/// MinesweeperGameView(model: MinesweeperModel(rows: 9, columns: 9, mineCount: 10))
///     .grid(spacing: 4, cell: MinesweeperCell.self)
///     .onInput { coord, score in
///         print("Revealed (\(coord.row), \(coord.col)) — score: \(score)")
///     }
///     .onCompletion { didWin in
///         print(didWin ? "You cleared the board!" : "Boom!")
///     }
/// ```
///
/// ### Interactions
/// - **Tap** a hidden cell to reveal it. If it has zero adjacent mines the reveal flood-fills outward automatically.
/// - **Long-press** a hidden cell to plant a flag; long-press again to remove it. Flagged cells cannot be revealed by tap.
///
/// ### Scoring
/// Each safely revealed cell awards one point. The cumulative score is reported through ``onInput(_:)`` after every reveal.
///
/// ### Mine placement
/// If `MinesweeperModel.mines` is empty the view generates mines on the player's first tap, ensuring that cell and
/// all its immediate neighbors are mine-free.
public struct MinesweeperGameView: View {

    // MARK: - Configuration

    private let model: MinesweeperModel
    private var gridSpacing: CGFloat = 4

    private var cellFactory: (_ row: Int, _ col: Int, _ state: MinesweeperCellState) -> AnyView =
    { row, col, state in
        AnyView(MinesweeperCell(row: row, column: col, state: state))
    }

    private var onInputCallback: ((_ coord: MinesweeperCoord, _ score: Int) -> Void)? = nil
    private var onCompletionCallback: ((_ didWin: Bool) -> Void)? = nil

    // MARK: - State

    @State private var cellStates: [[MinesweeperCellState]]
    @State private var activeMines: Set<MinesweeperCoord>
    @State private var score: Int
    @State private var isGameOver: Bool

    // MARK: - Init

    /// Creates a new game view with the given model.
    ///
    /// Apply `.grid(spacing:cell:)`, `.onInput(_:)`, and `.onCompletion(_:)` modifiers before
    /// inserting the view into the hierarchy.
    ///
    /// - Parameter model: The ``MinesweeperModel`` that defines the grid dimensions and mine count.
    public init(model: MinesweeperModel) {
        self.model = model
        _cellStates = State(initialValue:
            Array(repeating: Array(repeating: .hidden, count: model.columns), count: model.rows)
        )
        _activeMines = State(initialValue: model.mines)
        _score = State(initialValue: 0)
        _isGameOver = State(initialValue: false)
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: gridSpacing) {
            ForEach(0..<model.rows, id: \.self) { row in
                HStack(spacing: gridSpacing) {
                    ForEach(0..<model.columns, id: \.self) { col in
                        let coord = MinesweeperCoord(row: row, col: col)
                        cellFactory(row, col, cellStates[row][col])
                            .onTapGesture { handleTap(at: coord) }
                            .onLongPressGesture { handleLongPress(at: coord) }
                    }
                }
            }
        }
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

    // MARK: - Helpers

    private func handleTap(at coord: MinesweeperCoord) {
        guard !isGameOver else { return }
        guard case .hidden = cellStates[coord.row][coord.col] else { return }

        // Auto-generate mines on first tap, guaranteeing the tapped cell + its neighbors are safe
        if activeMines.isEmpty && model.mines.isEmpty {
            let safeZone = Set([coord] + model.neighbors(of: coord))
            activeMines = model.generateMines(avoiding: safeZone)
        }

        if activeMines.contains(coord) {
            triggerGameOver(explodedAt: coord)
        } else {
            revealCells(from: coord)
            checkWin()
        }
    }

    private func handleLongPress(at coord: MinesweeperCoord) {
        guard !isGameOver else { return }
        switch cellStates[coord.row][coord.col] {
        case .hidden:  cellStates[coord.row][coord.col] = .flagged
        case .flagged: cellStates[coord.row][coord.col] = .hidden
        default:       break
        }
    }

    /// BFS flood-fill reveal: auto-expands through cells with zero adjacent mines.
    private func revealCells(from start: MinesweeperCoord) {
        var queue: [MinesweeperCoord] = [start]
        var visited: Set<MinesweeperCoord> = []

        while !queue.isEmpty {
            let coord = queue.removeFirst()
            guard !visited.contains(coord) else { continue }
            guard case .hidden = cellStates[coord.row][coord.col] else { continue }
            visited.insert(coord)

            let adjCount = model.adjacentMineCount(for: coord, in: activeMines)
            cellStates[coord.row][coord.col] = .revealed(adjacentMines: adjCount)
            score += 1
            onInputCallback?(coord, score)

            if adjCount == 0 {
                for neighbor in model.neighbors(of: coord) {
                    guard !visited.contains(neighbor) else { continue }
                    if case .hidden = cellStates[neighbor.row][neighbor.col] {
                        queue.append(neighbor)
                    }
                }
            }
        }
    }

    private func triggerGameOver(explodedAt coord: MinesweeperCoord) {
        cellStates[coord.row][coord.col] = .exploded
        for mine in activeMines where mine != coord {
            if case .hidden = cellStates[mine.row][mine.col] {
                cellStates[mine.row][mine.col] = .mineRevealed
            }
        }
        isGameOver = true
        onCompletionCallback?(false)
    }

    private func checkWin() {
        let totalSafe = model.rows * model.columns - activeMines.count
        guard score >= totalSafe else { return }
        isGameOver = true
        onCompletionCallback?(true)
    }
}
