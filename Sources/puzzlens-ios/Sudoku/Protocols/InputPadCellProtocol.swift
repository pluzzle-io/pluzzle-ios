import SwiftUI

/// A view that represents a single number button on the Sudoku input pad.
///
/// Conform to this protocol to supply custom number buttons to ``SudokuGameView``
/// via the `.input(cell:)` modifier.
///
/// - `label` — The number to display on the button (`"1"`–`"9"`).
/// - `onTap` — Call this when the button is tapped.
public protocol InputPadCellProtocol: View {
    init(label: String, onTap: @escaping () -> Void)
}
