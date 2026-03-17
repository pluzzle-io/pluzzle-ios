import SwiftUI

/// An alternative number-pad button for ``SudokuGameView``, styled with an indigo rounded rectangle.
///
/// Use this as a drop-in for ``SudokuInputPadCell`` when you prefer a taller,
/// shadowed button appearance.
///
/// ```swift
/// SudokuGameView(model: model)
///     .input(cell: SudokuInputPad.self)
/// ```
struct SudokuInputPad: View, InputPadCellProtocol {
    var label: String
    var onTap: () -> Void

    init(label: String, onTap: @escaping () -> Void) {
        self.label = label
        self.onTap = onTap
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(.indigo)
                .shadow(radius: 1, x: 0, y: 1)
            Text(label)
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.vertical, 10)
        }
        .onTapGesture { onTap() }
        .frame(height: 50)
    }
}
