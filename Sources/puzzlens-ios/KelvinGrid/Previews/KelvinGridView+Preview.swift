import SwiftUI

#Preview {
    KelvinGridView(model: .example)
        .grid(spacing: 8, cell: KelvinGridCell.self)
        .input(cell: KelvinKey.self)
        .onInput { guess, states in
            let correct = states.filter { $0 == .correct }.count
            print("Guess: \(guess) — \(correct)/\(KelvinGridModel.example.columns) correct")
        }
        .onCompletion { didWin in
            print(didWin ? "Correct!" : "Game over. The word was \(KelvinGridModel.example.targetWord).")
        }
}
