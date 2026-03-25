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
            ZStack {
                Color.red
                HStack(spacing: 12) {
                    Button {
                        isNotesMode.toggle()
                    } label: {
                        Label(
                            isNotesMode ? "Notes On" : "Notes Off",
                            systemImage: isNotesMode ? "pencil.circle.fill" : "pencil.circle"
                        )
                        .font(.subheadline.bold())
                        .foregroundStyle(isNotesMode ? Color.blue : Color.secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            isNotesMode ? Color.blue.opacity(0.12) : Color(.systemGray6),
                            in: Capsule()
                        )
                    }
                    Button {
                        model.reset()
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.secondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6), in: Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onInput { row, col, value in
            print("Placed \(value.map(String.init) ?? "nil") at (\(row), \(col))")
        }
        .onCompletion { isCorrect in
            print(isCorrect ? "Puzzle solved correctly!" : "Board filled — solution incorrect.")
        }
}
