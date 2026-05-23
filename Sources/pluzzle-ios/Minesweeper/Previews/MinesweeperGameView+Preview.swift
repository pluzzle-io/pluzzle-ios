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

#Preview("Seeded — today") {
    @Previewable @State var model = MinesweeperModel(
        rows: 9, columns: 9, mineCount: 10, generationMode: .seeded(.now)
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
