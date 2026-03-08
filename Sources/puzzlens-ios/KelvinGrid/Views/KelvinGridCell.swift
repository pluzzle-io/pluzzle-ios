import SwiftUI

/// The default cell used by `KelvinGridView`.
///
/// Colour scheme:
/// - **Green**   — correct letter, correct position (`.correct`).
/// - **Red**     — correct letter, wrong position (`.misplaced`).
/// - **Orange → Gray** — letter not in word; full orange at distance 1, fading toward gray at distance 5 (`.warm`).
/// - **Dark gray** — letter not in word and far alphabetically (`.cold`).
/// - **White/outlined** — empty or pending (unsubmitted letter).
///
/// When `isActiveRow` is `true` the border is rendered in the accent colour to indicate
/// that this row is currently being typed.
struct KelvinGridCell: View, KelvinGridCellProtocol {
    var letter: String
    var state: KelvinCellState
    var isActiveRow: Bool

    init(letter: String, state: KelvinCellState, isActiveRow: Bool) {
        self.letter = letter
        self.state = state
        self.isActiveRow = isActiveRow
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(borderColor, lineWidth: borderWidth)
                )
            Text(letter)
                .font(.title2.bold())
                .foregroundStyle(foregroundColor)
        }
    }

    private var backgroundColor: Color {
        switch state {
        case .empty, .pending:
            return Color(.systemBackground)
        case .correct:
            return .red
        case .misplaced:
            return .yellow
        case .warm(let distance):
            // (distance=1) → (distance=5)
            return .yellow.opacity(0.6)
        case .cold:
            return Color(.systemGray3)
        }
    }

    private var foregroundColor: Color {
        switch state {
        case .empty: return .clear
        case .pending: return .primary
        default: return .white
        }
    }

    private var borderColor: Color {
        switch state {
        case .empty, .pending:
            return isActiveRow ? Color.accentColor : Color(.systemGray4)
        default:
            return .clear
        }
    }

    private var borderWidth: CGFloat {
        switch state {
        case .empty:   return isActiveRow ? 2.0 : 1.5
        case .pending: return isActiveRow ? 2.5 : 1.5
        default:       return 0
        }
    }
}
