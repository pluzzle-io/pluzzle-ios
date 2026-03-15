import SwiftUI

#Preview {
    MinesweeperGameView(model: .example)
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
