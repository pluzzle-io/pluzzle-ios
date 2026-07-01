import SwiftUI

/// The default cell view used by ``ShikakuGameView``.
///
/// Visual scheme:
/// - **Blank uncovered cell** — muted gray tile.
/// - **HintEligible cell** — orange-tinted uncovered tile indicating the player can tap it to reveal its solution rectangle.
/// - **Clue cell** — tile with the clue number centred in bold.
/// - **Covered cell** — tinted background showing it belongs to a placed rectangle.
/// - **Preview cell** — lighter tint indicating the rectangle currently being drawn.
/// - **Overlap cell** — orange overlay while a drag preview would overwrite an existing rectangle.
/// - **Violation** — red tint overlay when the covering rectangle breaks a rule.
struct ShikakuCell: ShikakuCellProtocol {
    let row: Int
    let column: Int
    let state: ShikakuCellState

    init(row: Int, column: Int, state: ShikakuCellState) {
        self.row = row
        self.column = column
        self.state = state
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundColor)

            if state.isOverlap {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.orange.opacity(0.55))
            } else if state.isViolation {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.red.opacity(0.25))
            }

            if let clue = state.clue {
                Text("\(clue)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(clueColor)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .animation(.easeInOut(duration: 0.12), value: state)
    }

    // MARK: - Private helpers

    private var backgroundColor: Color {
        if state.isPreview {
            return Color.accentColor.opacity(0.25)
        }
        if let index = state.colorIndex {
            return palette[index % palette.count].opacity(0.55)
        }
        if state.isHintEligible {
            return Color.orange.opacity(0.35)
        }
        return Color(.systemGray5)
    }

    private var clueColor: Color {
        if state.colorIndex != nil || state.isPreview {
            return .white
        }
        return Color(.label)
    }

    private let palette: [Color] = [
        .blue, .green, .orange, .purple, .pink,
        .teal, .indigo, .cyan, .mint,
        Color(red: 0.85, green: 0.45, blue: 0.10),
    ]
}
