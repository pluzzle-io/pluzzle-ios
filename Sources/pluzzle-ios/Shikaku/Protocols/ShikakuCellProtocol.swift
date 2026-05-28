import SwiftUI

/// A view that renders a single cell in a ``ShikakuGameView`` grid.
///
/// Conform a custom SwiftUI view to this protocol and pass it to the `.grid(spacing:cell:)`
/// modifier to replace the default ``ShikakuCell`` appearance.
///
/// ```swift
/// struct MyCell: ShikakuCellProtocol {
///     let row: Int
///     let column: Int
///     let state: ShikakuCellState
///
///     init(row: Int, column: Int, state: ShikakuCellState) {
///         self.row = row; self.column = column; self.state = state
///     }
///
///     var body: some View { … }
/// }
///
/// ShikakuGameView(model: $model)
///     .grid(spacing: 2, cell: MyCell.self)
/// ```
public protocol ShikakuCellProtocol: View {
    /// Creates a cell view for the given position and state.
    ///
    /// - Parameters:
    ///   - row: Zero-based row index of the cell.
    ///   - column: Zero-based column index of the cell.
    ///   - state: The current ``ShikakuCellState`` describing all display information for this cell.
    init(row: Int, column: Int, state: ShikakuCellState)
}
