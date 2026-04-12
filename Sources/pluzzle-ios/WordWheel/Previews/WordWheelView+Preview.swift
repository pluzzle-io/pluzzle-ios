import SwiftUI

#Preview {
    WordWheelView(model: .example)
        .input(cell: WordWheelLetterCell.self)
        .actionButton(cell: WordWheelActionButton.self)
        .onWordSubmitted { word in
            print(word)
        }
        .padding()
}
