import SwiftUI

#Preview {
    SudokuGameView(model: .example)
        .grid(spacing: 1, cell: SudokuGameCell.self)
        .input(cell: SudokuInputPadCell.self)
        .onInput { row, col, value in
            print("Placed \(value.map(String.init) ?? "nil") at (\(row), \(col))")
        }
        .onCompletion { isCorrect in
            print(isCorrect ? "Puzzle solved correctly!" : "Board filled — solution incorrect.")
        }
        .padding()
}
