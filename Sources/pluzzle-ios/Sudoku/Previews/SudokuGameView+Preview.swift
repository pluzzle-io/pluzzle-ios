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
    @Previewable @State var isNotesMode = false
    SudokuGameView(model: $model, isNotesMode: $isNotesMode)
        .grid(spacing: 1, cell: SudokuGameCell.self)
        .input(cell: SudokuInputPadCell.self)
        .accessoryView {
            Color.red
                .overlay {
                    Button {
                        isNotesMode.toggle()
                    } label: {
                        Text(isNotesMode ? "Notes ON" : "Notes OFF")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isNotesMode ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundStyle(isNotesMode ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
        }
        .onInput { row, col, value in
            print("Placed \(value.map(String.init) ?? "nil") at (\(row), \(col))")
        }
        .onCompletion { isCorrect in
            print(isCorrect ? "Puzzle solved correctly!" : "Board filled — solution incorrect.")
        }
}
