import SwiftUI

#Preview("Random") {
    @Previewable @State var model = MinesweeperModel(
        rows: 9, columns: 9, mineCount: 10, generationMode: .random
    )
    MinesweeperGameView(model: $model)
        .grid(spacing: 4, cell: MinesweeperCell.self)
        .onInput { coord, score in
            print("Revealed (\(coord.row), \(coord.col)) — score: \(score)")
        }
        .onCompletion { didWin in
            print(didWin ? "You win!" : "Game over!")
        }
        .padding()
        .aspectRatio(1, contentMode: .fit)
}

#Preview("Example grid") {
    @Previewable @State var model = MinesweeperModel.example
    MinesweeperGameView(model: $model)
        .grid(spacing: 4, cell: MinesweeperCell.self)
        .onInput { coord, score in
            print("Revealed (\(coord.row), \(coord.col)) — score: \(score)")
        }
        .onCompletion { didWin in
            print(didWin ? "You win!" : "Game over!")
        }
        .padding()
        .aspectRatio(1, contentMode: .fit)
}
