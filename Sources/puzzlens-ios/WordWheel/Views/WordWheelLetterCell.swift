import SwiftUI

/// The default letter tile used by `WordWheelView`.
///
/// - Main letter: filled with indigo.
/// - Used tile: dimmed grey (cannot be tapped again for the current word).
/// - Available tile: filled with blue.
struct WordWheelLetterCell: View, WordWheelLetterCellProtocol {
    var letter: String
    var isMain: Bool
    var isUsed: Bool
    var onTap: () -> Void

    init(letter: String, isMain: Bool, isUsed: Bool, onTap: @escaping () -> Void) {
        self.letter = letter
        self.isMain = isMain
        self.isUsed = isUsed
        self.onTap = onTap
    }

    private var fillColor: Color {
        if isUsed { return .gray.opacity(0.4) }
        return isMain ? .indigo : .blue
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(fillColor)
                .shadow(radius: isMain ? 4 : 2, x: 0, y: 2)
            Text(letter)
                .font(isMain ? .title2.bold() : .headline)
                .foregroundStyle(.white)
        }
        .onTapGesture {
            guard !isUsed else { return }
            onTap()
        }
    }
}
