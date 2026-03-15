import SwiftUI

public struct MinesweeperGameView: View {

    private let model: MinesweeperModel
    private var gridSpacing: CGFloat = 4
    private var cellFactory: (_ row: Int, _ col: Int, _ state: MinesweeperCellState) -> AnyView
    private var onInputCallback: ((_ coord: MinesweeperCoord, _ score: Int) -> Void)?
    private var onCompletionCallback: ((_ didWin: Bool) -> Void)?

    @State private var cellStates: [[MinesweeperCellState]]
    @State private var activeMines: Set<MinesweeperCoord>
    @State private var score: Int
    @State private var isGameOver: Bool

    public init(model: MinesweeperModel) {
        self.model = model
        self.cellFactory = { row, col, state in
            AnyView(MinesweeperCell(row: row, column: col, state: state))
        }
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

    public func grid<T: MinesweeperCellProtocol>(spacing: CGFloat, cell: T.Type) -> Self {
        var copy = self
        copy.gridSpacing = spacing
        copy.cellFactory = { row, col, state in AnyView(T(row: row, column: col, state: state)) }
        return copy
    }

    /// Fires each time a safe cell is revealed, with the cell's coordinate and cumulative score.
    public func onInput(_ handler: @escaping (_ coord: MinesweeperCoord, _ score: Int) -> Void) -> Self {
        var copy = self
        copy.onInputCallback = handler
        return copy
    }

    /// Fires when the game ends. `didWin` is `true` if all safe cells were revealed, `false` if a mine was hit.
    public func onCompletion(_ handler: @escaping (_ didWin: Bool) -> Void) -> Self {
        var copy = self
        copy.onCompletionCallback = handler
        return copy
    }

    // MARK: - Game Logic

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
