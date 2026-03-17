import SwiftUI

/// A view that represents a single cell in the KelvinGrid.
///
/// Conform to this protocol to supply a custom cell to ``KelvinGridView``
/// via the `.grid(spacing:cell:)` modifier.
///
/// ```swift
/// struct MyCell: KelvinGridCellProtocol {
///     let letter: String
///     let state: KelvinCellState
///     let isActiveRow: Bool
///
///     init(letter: String, state: KelvinCellState, isActiveRow: Bool) {
///         self.letter = letter; self.state = state; self.isActiveRow = isActiveRow
///     }
///
///     var body: some View { … }
/// }
///
/// KelvinGridView(model: model)
///     .grid(spacing: 8, cell: MyCell.self)
/// ```
public protocol KelvinGridCellProtocol: View {
    /// Creates a cell for the given letter, evaluation state, and whether it belongs to the active row.
    ///
    /// - Parameters:
    ///   - letter: The letter displayed in the cell, or an empty string if the cell is unfilled.
    ///   - state: The ``KelvinCellState`` that determines how the cell is coloured.
    ///   - isActiveRow: `true` when this cell belongs to the row currently being typed.
    ///     Use this flag to render a highlighted border around the active row.
    init(letter: String, state: KelvinCellState, isActiveRow: Bool)
}
