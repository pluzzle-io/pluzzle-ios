import SwiftUI

#Preview {
    @Previewable @State var model: SudokuGameModel = {
        var m = SudokuGameModel.example
        m.notes = Array(repeating: Array(repeating: Set<Int>(), count: 9), count: 9)
        m.notes![1][6] = [3, 8]
        m.notes![3][2] = [9]
        m.notes![4][0] = [4, 2]
        m.notes![4][1] = [2]
        m.notes![5][1] = [1, 3]
        return m
    }()
    SudokuGameView(model: $model)
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
