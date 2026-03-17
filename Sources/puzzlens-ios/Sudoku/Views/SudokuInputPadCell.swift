import SwiftUI

/// The default number-pad button used by ``SudokuGameView``.
///
/// Renders as a blue rounded rectangle displaying the digit label in white.
/// This is the cell type registered by default in ``SudokuGameView``;
/// replace it with ``SudokuInputPad`` or a custom ``InputPadCellProtocol`` conformance
/// via the `.input(cell:)` modifier.
struct SudokuInputPadCell: View, InputPadCellProtocol {
    var label: String
    var onTap: () -> Void

    init(label: String, onTap: @escaping () -> Void) {
        self.label = label
        self.onTap = onTap
    }

    var body: some View {
        Rectangle()
            .fill(Color.blue)
            .overlay(
                Text(label)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.vertical, 8)
            )
            .onTapGesture { onTap() }
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
