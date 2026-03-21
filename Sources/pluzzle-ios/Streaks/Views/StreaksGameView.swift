import SwiftUI

/// A SwiftUI view that presents a Streaks puzzle.
///
/// The player drags a continuous path through every cell in the N×M grid.
/// Cells may only be visited once, and each new cell must be adjacent
/// (orthogonally or diagonally) to the previous one.
/// If the finger is lifted before all cells are visited the path resets.
/// When all cells are connected `onCompletion` fires with `true`.
public struct StreaksGameView: View {

    private let model: StreaksModel

    // MARK: - State

    @State private var selectedPath: [(row: Int, col: Int)] = []
    @State private var cellStates: [[StreaksCellState]]
    @State private var isComplete: Bool = false

    // MARK: - Configuration

    private var gridSpacing: CGFloat = 8

    private var cellFactory: (_ row: Int, _ col: Int, _ state: StreaksCellState) -> AnyView = { row, col, state in
        AnyView(StreaksCell(row: row, column: col, state: state))
    }

    private var onInputCallback: ((_ path: [(row: Int, col: Int)]) -> Void)? = nil
    private var onCompletionCallback: ((_ didWin: Bool) -> Void)? = nil

    // MARK: - Init

    /// Creates a new Streaks game view with the given model.
    ///
    /// Apply `.grid(spacing:cell:)`, `.onInput(_:)`, and `.onCompletion(_:)` modifiers before
    /// inserting the view into the hierarchy.
    ///
    /// - Parameter model: The ``StreaksModel`` defining the grid dimensions and blocked cells.
    public init(model: StreaksModel) {
        self.model = model
        _cellStates = State(initialValue:
            (0..<model.rows).map { row in
                (0..<model.columns).map { col in
                    model.isBlocked(row: row, col: col) ? .blocked : .unselected
                }
            }
        )
    }

    // MARK: - Body

    public var body: some View {
        GeometryReader { geo in
            let cellW = cellWidth(totalWidth: geo.size.width)
            let cellH = cellHeight(totalHeight: geo.size.height)

            gridContent(cellWidth: cellW, cellHeight: cellH)
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .named("streaksGrid"))
                        .onChanged { value in
                            processDrag(at: value.location, cellWidth: cellW, cellHeight: cellH)
                        }
                        .onEnded { _ in
                            processDragEnd()
                        }
                )
        }
        .coordinateSpace(name: "streaksGrid")
    }

    // MARK: - Layout

    private func cellWidth(totalWidth: CGFloat) -> CGFloat {
        (totalWidth - gridSpacing * CGFloat(model.columns - 1)) / CGFloat(model.columns)
    }

    private func cellHeight(totalHeight: CGFloat) -> CGFloat {
        (totalHeight - gridSpacing * CGFloat(model.rows - 1)) / CGFloat(model.rows)
    }

    @ViewBuilder
    private func gridContent(cellWidth: CGFloat, cellHeight: CGFloat) -> some View {
        VStack(spacing: gridSpacing) {
            ForEach(0..<model.rows, id: \.self) { row in
                HStack(spacing: gridSpacing) {
                    ForEach(0..<model.columns, id: \.self) { col in
                        cellFactory(row, col, cellStates[row][col])
                            .frame(width: cellWidth, height: cellHeight)
                    }
                }
            }
        }
    }

    // MARK: - Gesture Handling

    private func processDrag(at point: CGPoint, cellWidth: CGFloat, cellHeight: CGFloat) {
        guard !isComplete else { return }

        let col = max(0, min(model.columns - 1, Int(point.x / (cellWidth + gridSpacing))))
        let row = max(0, min(model.rows - 1, Int(point.y / (cellHeight + gridSpacing))))

        // Ignore blocked and already-visited cells
        if model.isBlocked(row: row, col: col) { return }
        if selectedPath.contains(where: { $0.row == row && $0.col == col }) { return }

        // New path start, or must be adjacent to the last cell
        if let last = selectedPath.last, !isAdjacent(last, (row: row, col: col)) { return }

        selectedPath.append((row: row, col: col))
        cellStates[row][col] = .selected(order: selectedPath.count)
        onInputCallback?(selectedPath)
    }

    private func processDragEnd() {
        guard !isComplete else { return }
        if selectedPath.count == model.totalCells {
            isComplete = true
            onCompletionCallback?(true)
        } else {
            resetPath()
        }
    }

    private func resetPath() {
        selectedPath = []
        cellStates = (0..<model.rows).map { row in
            (0..<model.columns).map { col in
                model.isBlocked(row: row, col: col) ? .blocked : .unselected
            }
        }
    }

    private func isAdjacent(_ a: (row: Int, col: Int), _ b: (row: Int, col: Int)) -> Bool {
        abs(a.row - b.row) <= 1 && abs(a.col - b.col) <= 1
    }

    // MARK: - Modifiers

    /// Replace the default grid cell with a custom view conforming to `StreaksCellProtocol`,
    /// and set the spacing between cells.
    public func grid<T: StreaksCellProtocol>(spacing: CGFloat, cell: T.Type) -> Self {
        var copy = self
        copy.gridSpacing = spacing
        copy.cellFactory = { row, col, state in
            AnyView(T(row: row, column: col, state: state))
        }
        return copy
    }

    /// Called each time the player extends the path by one cell.
    /// - Parameter handler: Receives the current path as an ordered array of `(row:col:)` coordinates.
    public func onInput(_ handler: @escaping (_ path: [(row: Int, col: Int)]) -> Void) -> Self {
        var copy = self
        copy.onInputCallback = handler
        return copy
    }

    /// Called when the player successfully connects every cell in the grid.
    /// - Parameter handler: Receives `true` when the streak is complete.
    public func onCompletion(_ handler: @escaping (_ didWin: Bool) -> Void) -> Self {
        var copy = self
        copy.onCompletionCallback = handler
        return copy
    }
}
