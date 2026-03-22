import SwiftUI

/// The default cell used by ``SudokuGameView``.
///
/// Colour scheme:
/// - **Green**  — pre-filled (fixed) cell from the puzzle definition.
/// - **Blue**   — editable cell that is currently selected.
/// - **Gray**   — editable cell that is not selected.
///
/// When `text` is empty and `notes` is non-empty, the cell renders pencil marks
/// in a 3×3 mini grid instead of a digit.
///
/// The displayed number animates via `numericText` content transition when the value changes.
struct SudokuGameCell: View, SudokuCellProtocol {
    @Binding var isSelected: Bool
    var text: String
    var isFixed: Bool
    var notes: Set<Int>?

    init(isSelected: Binding<Bool>, text: String, isFixed: Bool, notes: Set<Int>? = nil) {
        self._isSelected = isSelected
        self.text = text
        self.isFixed = isFixed
        self.notes = notes
    }

    private let noteColumns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 3)

    var body: some View {
        Rectangle()
            .fill(isFixed ? Color.green : (isSelected ? Color.blue : Color.gray))
            .overlay {
                if text.isEmpty, let notes, !notes.isEmpty {
                    LazyVGrid(columns: noteColumns, spacing: 0) {
                        ForEach(1...9, id: \.self) { digit in
                            Text(notes.contains(digit) ? "\(digit)" : "")
                                .font(.system(size: 8, weight: .regular))
                                .foregroundStyle(.white.opacity(0.85))
                                .minimumScaleFactor(0.5)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(2)
                } else {
                    Text(text)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                }
            }
    }
}
