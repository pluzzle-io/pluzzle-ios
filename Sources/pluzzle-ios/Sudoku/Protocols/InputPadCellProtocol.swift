import SwiftUI

/// A view that represents a single number button on the Sudoku input pad.
///
/// Conform to this protocol to supply custom number buttons to ``SudokuGameView``
/// via the `.input(cell:)` modifier.
///
/// ```swift
/// struct MyPadButton: InputPadCellProtocol {
///     let label: String
///     let onTap: () -> Void
///
///     init(label: String, onTap: @escaping () -> Void) {
///         self.label = label; self.onTap = onTap
///     }
///
///     var body: some View { … }
/// }
///
/// SudokuGameView(model: model)
///     .input(cell: MyPadButton.self)
/// ```
public protocol InputPadCellProtocol: View {
    /// Creates a number-pad button for the given label and tap handler.
    ///
    /// - Parameters:
    ///   - label: The digit string to display on the button (`"1"`–`"9"`).
    ///   - onTap: Call this closure when the button is tapped.
    init(label: String, onTap: @escaping () -> Void)
}
