import SwiftUI

/// A SwiftUI view that presents a fully interactive Takuzu (Binairo) binary puzzle.
///
/// Provide a ``TakuzuModel`` binding and optionally chain builder modifiers before inserting the
/// view into the hierarchy:
///
/// ```swift
/// @State private var model = TakuzuModel.example
///
/// var body: some View {
///     TakuzuGameView(model: $model)
///         .grid(spacing: 4, cell: TakuzuCell.self)
///         .showViolations(true)
///         .onCellTap { row, col, newValue in
///             print("Cell (\(row),\(col)) → \(newValue.map { $0 ? "1" : "0" } ?? "cleared")")
///         }
///         .onGameComplete { isCorrect in
///             print(isCorrect ? "Puzzle solved!" : "Board filled but incorrect.")
///         }
/// }
/// ```
///
/// ### Interactions
/// Tapping an editable (non-fixed) cell cycles through three states:
/// **empty → true ("1") → false ("0") → empty → …**
///
/// Fixed (given) cells cannot be tapped and do not participate in the cycle.
///
/// ### Violation highlighting
/// When `.showViolations(true)` is set (the default), cells that break a Takuzu rule
/// (balance, no-triples, or uniqueness) are highlighted. Pass `false` to disable this feedback.
///
/// ### Completion
/// ``onGameComplete(_:)`` fires once every cell is filled. The `Bool` argument is `true` when the
/// board matches the solution, `false` when the board is fully filled but wrong.
public struct TakuzuGameView: View {

    // MARK: - Configuration

    @Binding var model: TakuzuModel

    private var gridSpacing: CGFloat = 4
    private var shouldShowViolations: Bool = true

    private var cellFactory: (_ row: Int, _ col: Int, _ value: Bool?, _ isFixed: Bool, _ isViolation: Bool) -> AnyView = {
        row, col, value, isFixed, isViolation in
        AnyView(TakuzuCell(row: row, column: col, value: value, isFixed: isFixed, isViolation: isViolation))
    }

    // Callbacks
    private var onCellTapCallback: ((_ row: Int, _ col: Int, _ newValue: Bool?) -> Void)? = nil
    private var onGameCompleteCallback: ((_ isCorrect: Bool) -> Void)? = nil

    /// Guards completion callback — fires at most once per completed board.
    @State private var completionFired = false

    // MARK: - Init

    /// Creates a new Takuzu game view with the given model binding.
    ///
    /// Apply `.grid(spacing:cell:)`, `.showViolations(_:)`, `.onCellTap(_:)`, and
    /// `.onGameComplete(_:)` modifiers before inserting the view into the hierarchy.
    ///
    /// - Parameter model: A binding to the ``TakuzuModel`` that defines the puzzle and holds
    ///   all live player state. All state changes are written back through this binding.
    public init(model: Binding<TakuzuModel>) {
        self._model = model
    }

    // MARK: - Body

    public var body: some View {
        let violations = shouldShowViolations ? model.violations : []

        VStack(spacing: gridSpacing) {
            ForEach(0..<model.size, id: \.self) { row in
                HStack(spacing: gridSpacing) {
                    ForEach(0..<model.size, id: \.self) { col in
                        let value    = model.state[row][col]
                        let isFixed  = model.isFixed(row: row, col: col)
                        let isVio    = violations.contains(TakuzuCoord(row: row, col: col))

                        cellFactory(row, col, value, isFixed, isVio)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                guard !isFixed else { return }
                                handleTap(row: row, col: col)
                            }
                    }
                }
            }
        }
        .onChange(of: model.isComplete) { _, isComplete in
            if !isComplete { completionFired = false }
            if isComplete && !completionFired {
                completionFired = true
                onGameCompleteCallback?(model.isCorrect)
            }
        }
    }

    // MARK: - Modifiers

    /// Sets the cell spacing and registers a custom cell type conforming to ``TakuzuCellProtocol``.
    ///
    /// - Parameters:
    ///   - spacing: Points of space between adjacent cells.
    ///   - cell: A type conforming to ``TakuzuCellProtocol`` used to render each grid cell.
    public func grid<T: TakuzuCellProtocol>(spacing: CGFloat, cell: T.Type) -> Self {
        var copy = self
        copy.gridSpacing = spacing
        copy.cellFactory = { row, col, value, isFixed, isViolation in
            AnyView(T(row: row, column: col, value: value, isFixed: isFixed, isViolation: isViolation))
        }
        return copy
    }

    /// Controls whether cells that violate a Takuzu rule are visually highlighted.
    ///
    /// When `true` (the default), any cell that is part of a balance, no-triples, or uniqueness
    /// violation receives an `isViolation: true` flag so custom cells can render error feedback.
    ///
    /// - Parameter show: Pass `false` to disable violation highlighting entirely.
    public func showViolations(_ show: Bool) -> Self {
        var copy = self
        copy.shouldShowViolations = show
        return copy
    }

    /// Registers a handler that fires each time the player taps an editable cell.
    ///
    /// - Parameter handler: Receives the zero-based row, column, and the **new** value after
    ///   the cycle (`nil` = cleared back to empty, `true` = "1", `false` = "0").
    public func onCellTap(_ handler: @escaping (_ row: Int, _ col: Int, _ newValue: Bool?) -> Void) -> Self {
        var copy = self
        copy.onCellTapCallback = handler
        return copy
    }

    /// Registers a handler that fires once when every cell is filled.
    ///
    /// - Parameter handler: Receives `true` when the board matches the solution; `false` when
    ///   the board is fully filled but contains at least one error.
    public func onGameComplete(_ handler: @escaping (_ isCorrect: Bool) -> Void) -> Self {
        var copy = self
        copy.onGameCompleteCallback = handler
        return copy
    }

    // MARK: - Helpers

    /// Cycles a cell through: `nil → true → false → nil → …`
    private func handleTap(row: Int, col: Int) {
        let current = model.state[row][col]
        let next: Bool?
        switch current {
        case nil:   next = true
        case true:  next = false
        case false: next = nil
        }
        model.state[row][col] = next
        onCellTapCallback?(row, col, next)
    }
}
