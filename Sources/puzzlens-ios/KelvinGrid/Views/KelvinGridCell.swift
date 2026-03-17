import SwiftUI

/// The default cell used by ``KelvinGridView``.
///
/// Colour scheme:
/// - **Green**         — correct letter, correct position (`.correct`).
/// - **Orange**        — correct letter, wrong position (`.misplaced`).
/// - **Gray + offset** — letter not in word (`.wrong(offset)`); shows `+N` or `−N`
///   indicating how many alphabetical steps the guessed letter is above or below the correct one.
/// - **Gray outlined** — empty or pending (unsubmitted letter).
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
            if case .wrong(let offset) = state {
                VStack(spacing: 1) {
                    Text(letter)
                        .font(.title2.bold())
                        .foregroundStyle(Color.white)
                    Text(offsetLabel(offset))
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.85))
                }
            } else {
                Text(letter)
                    .font(.title2.bold())
                    .foregroundStyle(foregroundColor)
            }
        }
    }

    private func offsetLabel(_ offset: Int) -> String {
        offset >= 0 ? "+\(offset)" : "\(offset)"
    }

    private var backgroundColor: Color {
        switch state {
        case .empty, .pending:
            return Color(.systemGray5)
        case .correct:
            return .green
        case .misplaced:
            return .orange
        case .wrong:
            return Color(.systemGray2)
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
            return isActiveRow ? Color.accentColor : Color(.systemGray3)
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
