import SwiftUI

/// A view that renders a single cell in a ``MinesweeperGameView`` grid.
///
/// Conform a custom SwiftUI view to this protocol and pass it to the `.grid(spacing:cell:)` modifier
/// to replace the default ``MinesweeperCell`` appearance.
///
/// ```swift
/// struct MyCell: MinesweeperCellProtocol {
///     let row: Int
///     let column: Int
///     let state: MinesweeperCellState
///
///     init(row: Int, column: Int, state: MinesweeperCellState) {
///         self.row = row; self.column = column; self.state = state
///     }
///
///     var body: some View { … }
/// }
///
/// MinesweeperGameView(model: model)
///     .grid(spacing: 4, cell: MyCell.self)
/// ```
public protocol MinesweeperCellProtocol: View {
    /// Creates a cell view for the given position and state.
    ///
    /// - Parameters:
    ///   - row: Zero-based row index of the cell.
    ///   - column: Zero-based column index of the cell.
    ///   - state: The current ``MinesweeperCellState`` determining how the cell should be drawn.
    init(row: Int, column: Int, state: MinesweeperCellState)
}
