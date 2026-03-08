import SwiftUI

/// The default solution cell used by `WordWheelView` to display each found word.
struct WordWheelSolutionCell: View, WordWheelSolutionCellProtocol {
    var word: String

    init(word: String) {
        self.word = word
    }

    var body: some View {
        Text(word.capitalized)
            .font(.subheadline)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.orange.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
