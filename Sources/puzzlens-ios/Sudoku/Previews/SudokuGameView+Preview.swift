import SwiftUI

#Preview {
    VStack(spacing: 16) {
        SudokuGameView(model: .example)
            .grid(spacing: 1, cell: SudokuGameCell.self)
            .input(cell: SudokuInputPad.self)
            .onInput { row, col, value in
                print("Input \(value) at \(row), \(col)")
            }
            .onCompletion { correct in
                print("Completed \(correct ? "correct" : "incorrect")ly")
            }
    }
}
