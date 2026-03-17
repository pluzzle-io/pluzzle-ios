import SwiftUI

/// A 3×3 number pad (digits 1–9) used internally by ``SudokuGameView``.
///
/// Each button is rendered by the type-erased `makeCell` factory, allowing the parent
/// view to inject a custom ``InputPadCellProtocol`` implementation. Tapping a button
/// calls `onInput` with the corresponding integer value.
struct SudokuNumberPad: View {
    /// Factory that produces a type-erased button view for a given label and tap handler.
    var makeCell: (String, @escaping () -> Void) -> AnyView
    /// Called with the integer value (1–9) when a button is tapped.
    var onInput: (Int) -> Void

    private let rows: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"]
    ]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<rows.count, id: \.self) { r in
                HStack(spacing: 8) {
                    ForEach(rows[r], id: \.self) { label in
                        makeCell(label) {
                            onInput(Int(label)!)
                        }
                    }
                }
            }
        }
    }
}
