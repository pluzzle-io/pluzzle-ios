import SwiftUI

/// A view that represents a single cell in the Streaks grid.
///
/// Conform to this protocol to supply a custom cell to ``StreaksGameView``
/// via the `.grid(spacing:cell:)` modifier.
///
/// ```swift
/// struct MyCell: StreaksCellProtocol {
///     let row: Int
///     let column: Int
///     let state: StreaksCellState
///
///     init(row: Int, column: Int, state: StreaksCellState) {
///         self.row = row; self.column = column; self.state = state
///     }
///
///     var body: some View { … }
/// }
///
/// StreaksGameView(model: model)
///     .grid(spacing: 8, cell: MyCell.self)
/// ```
public protocol StreaksCellProtocol: View {
    /// Creates a cell view for the given position and selection state.
    ///
    /// - Parameters:
    ///   - row: Zero-based row index of the cell.
    ///   - column: Zero-based column index of the cell.
    ///   - state: The current ``StreaksCellState`` of the cell.
    init(row: Int, column: Int, state: StreaksCellState)
}
