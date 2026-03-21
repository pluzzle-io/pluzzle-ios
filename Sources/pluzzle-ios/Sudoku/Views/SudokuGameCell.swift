import SwiftUI

/// The default cell used by ``SudokuGameView``.
///
/// Colour scheme:
/// - **Green**  — pre-filled (fixed) cell from the puzzle definition.
/// - **Blue**   — editable cell that is currently selected.
/// - **Gray**   — editable cell that is not selected.
///
/// The displayed number animates via `numericText` content transition when the value changes.
struct SudokuGameCell: View, SudokuCellProtocol {
    @Binding var isSelected: Bool
    var text: String
    var isFixed: Bool

    init(isSelected: Binding<Bool>, text: String, isFixed: Bool) {
        self._isSelected = isSelected
        self.text = text
        self.isFixed = isFixed
    }

    var body: some View {
        Rectangle()
            .fill(isFixed ? Color.green : (isSelected ? Color.blue : Color.gray))
            .overlay(
                Text(text)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            )
    }
}
