import SwiftUI

#Preview("Random") {
    MinesweeperGameView(model: MinesweeperModel(rows: 9, columns: 9, mineCount: 10, generationMode: .random))
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
    MinesweeperGameView(model: MinesweeperModel(rows: 9, columns: 9, mineCount: 10, generationMode: .seeded(.now)))
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
