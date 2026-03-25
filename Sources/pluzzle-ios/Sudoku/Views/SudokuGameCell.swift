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
/// The digit always animates via a `numericText` content transition, including the
/// initial appearance when an empty cell is first filled. This works because `Text`
/// is always present in the view hierarchy (stable identity), so SwiftUI can diff
/// the old and new values even when transitioning from an empty cell.
struct SudokuGameCell: View, SudokuCellProtocol {
    var isSelected: Bool
    var text: String
    var isFixed: Bool
    var notes: Set<Int>?

    init(isSelected: Bool, text: String, isFixed: Bool, notes: Set<Int>? = nil) {
        self.isSelected = isSelected
        self.text = text
        self.isFixed = isFixed
        self.notes = notes
    }

    private let noteColumns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 3)

    var body: some View {
        Rectangle()
            .fill(isFixed ? Color.green : (isSelected ? Color.blue : Color.gray))
            .overlay {
                ZStack {
                    // Notes layer — visible only while the cell is empty.
                    if text.isEmpty, let notes, !notes.isEmpty {
                        LazyVGrid(columns: noteColumns, spacing: 0) {
                            ForEach(1...9, id: \.self) { digit in
                                Text(notes.contains(digit) ? "\(digit)" : "")
                                    .font(.system(size: 8, weight: .regular))
                                    .foregroundStyle(.white.opacity(0.85))
                                    .minimumScaleFactor(0.5)
                            }
                        }
                        .padding(2)
                    }

                    // Digit layer — always present so `contentTransition` has a stable
                    // view identity to diff against, firing even on "" → "5" transitions.
                    Text(text)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                        .animation(.default, value: text)
                }
            }
    }
}
