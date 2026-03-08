import SwiftUI

#Preview {
    WordWheelView(model: .example)
        .letterCell(cell: WordWheelLetterCell.self)
        .actionButton(cell: WordWheelActionButton.self)
        .solutionCell(cell: WordWheelSolutionCell.self)
        .onWordSubmitted { word, isValid in
            print("\(word) — \(isValid ? "valid" : "invalid")")
        }
        .onCompletion {
            print("Puzzle complete!")
        }
        .padding()
}
