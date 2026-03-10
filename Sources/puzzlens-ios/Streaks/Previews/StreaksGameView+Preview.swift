import SwiftUI

#Preview {
    StreaksGameView(model: .example)
        .grid(spacing: 8, cell: StreaksCell.self)
        .onInput { path in
            print("Path: \(path.count)/\(StreaksModel.example.totalCells) cells")
        }
        .onCompletion { didWin in
            print(didWin ? "Streak complete!" : "")
        }
        .padding()
        .aspectRatio(1, contentMode: .fit)
}
