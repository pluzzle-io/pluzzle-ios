import SwiftUI

/// A view that renders a single cell in a Sudoku grid.
///
/// Conform to this protocol to supply a custom cell to ``SudokuGameView``
/// via the `.grid(spacing:cell:)` modifier.
///
/// ```swift
/// struct MyCell: SudokuCellProtocol {
///     @Binding var isSelected: Bool
///     let text: String
///     let isFixed: Bool
///
///     init(isSelected: Binding<Bool>, text: String, isFixed: Bool) {
///         self._isSelected = isSelected; self.text = text; self.isFixed = isFixed
///     }
///
///     var body: some View { … }
/// }
///
/// SudokuGameView(model: model)
///     .grid(spacing: 2, cell: MyCell.self)
/// ```
public protocol SudokuCellProtocol: View {
    /// Creates a cell view for the given selection state, display text, and fixed flag.
    ///
    /// - Parameters:
    ///   - isSelected: A binding that is `true` when this cell is currently selected.
    ///     Update the binding when the cell is tapped (unless it is fixed).
    ///   - text: The digit to display (`"1"`–`"9"`), or an empty string if the cell is blank.
    ///   - isFixed: `true` if the cell was pre-filled in the puzzle and cannot be edited.
    init(isSelected: Binding<Bool>, text: String, isFixed: Bool)
}
