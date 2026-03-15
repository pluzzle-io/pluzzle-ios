import SwiftUI

/// A view that renders a single cell in a Sudoku grid.
///
/// Conform to this protocol to supply a custom cell to ``SudokuGameView``
/// via the `.grid(spacing:cell:)` modifier.
///
/// - `isSelected` — A binding indicating whether this cell is currently selected by the player.
/// - `text`       — The number to display (`"1"`–`"9"`), or an empty string if the cell is blank.
/// - `isFixed`    — `true` if the cell was pre-filled in the puzzle and cannot be edited.
public protocol SudokuCellProtocol: View {
    init(isSelected: Binding<Bool>, text: String, isFixed: Bool)
}
