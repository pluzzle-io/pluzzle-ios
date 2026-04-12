import SwiftUI

#Preview {
    WordWheelView(model: .example)
        .input(cell: WordWheelLetterCell.self)
        .actionButton(cell: WordWheelActionButton.self)
        .output(cell: WordWheelSolutionCell.self)
        .onWordSubmitted { word, isValid in
            print("\(word) — \(isValid ? "valid" : "invalid")")
        }
        .onCompletion {
            print("Puzzle complete!")
        }
        .padding()
}
