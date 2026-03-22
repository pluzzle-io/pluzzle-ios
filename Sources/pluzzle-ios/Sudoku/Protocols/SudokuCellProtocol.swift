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
///     let notes: Set<Int>?
///
///     init(isSelected: Binding<Bool>, text: String, isFixed: Bool, notes: Set<Int>? = nil) {
///         self._isSelected = isSelected; self.text = text; self.isFixed = isFixed; self.notes = notes
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
    ///   - notes: The candidate digits (1–9) the player has pencilled in for this cell.
    ///     `nil` when no notes have been written. Displayed only when `text` is empty.
    init(isSelected: Binding<Bool>, text: String, isFixed: Bool, notes: Set<Int>?)
}

extension SudokuCellProtocol {
    /// Convenience initialiser that omits `notes`, defaulting to `nil`.
    public init(isSelected: Binding<Bool>, text: String, isFixed: Bool) {
        self.init(isSelected: isSelected, text: text, isFixed: isFixed, notes: nil)
    }
}
