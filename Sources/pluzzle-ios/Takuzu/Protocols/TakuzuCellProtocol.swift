import SwiftUI

/// A view that represents a single cell in a ``TakuzuGameView`` grid.
///
/// Conform to this protocol to supply a custom cell to ``TakuzuGameView``
/// via the `.grid(spacing:cell:)` modifier.
///
/// ```swift
/// struct MyCell: TakuzuCellProtocol {
///     let row: Int
///     let column: Int
///     let value: Bool?
///     let isFixed: Bool
///     let isViolation: Bool
///
///     init(row: Int, column: Int, value: Bool?, isFixed: Bool, isViolation: Bool) {
///         self.row = row
///         self.column = column
///         self.value = value
///         self.isFixed = isFixed
///         self.isViolation = isViolation
///     }
///
///     var body: some View { … }
/// }
///
/// TakuzuGameView(model: $model)
///     .grid(spacing: 4, cell: MyCell.self)
/// ```
public protocol TakuzuCellProtocol: View {
    /// Creates a cell view for the given position and state.
    ///
    /// - Parameters:
    ///   - row: Zero-based row index of the cell.
    ///   - column: Zero-based column index of the cell.
    ///   - value: The current cell value. `nil` = empty/unfilled, `true` = one binary state (e.g. "1"), `false` = the other (e.g. "0").
    ///   - isFixed: `true` when this cell was a given in the original puzzle and cannot be edited.
    ///   - isViolation: `true` when this cell is part of a rule violation (balance, no-triples, or uniqueness).
    ///   - isHintEligible: `true` when hint mode is active and this cell is empty and editable — the player
    ///     can tap it to fill it with the correct solution value. Use this to render a visual hint indicator.
    init(row: Int, column: Int, value: Bool?, isFixed: Bool, isViolation: Bool, isHintEligible: Bool)
}
