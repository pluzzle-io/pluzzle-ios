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
        Button(action: onTap) {
            Rectangle()
                .fill(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    Text(label)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.vertical, 8)
                )
        }
        .buttonStyle(.plain)
        .frame(maxHeight: 50)
    }
}
