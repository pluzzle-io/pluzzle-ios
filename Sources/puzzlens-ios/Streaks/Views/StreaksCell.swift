import SwiftUI

/// The default cell view used by ``StreaksGameView``.
///
/// Colour scheme:
/// - **Gray (light)**  — unselected; available to be added to the path.
/// - **Accent colour** — selected; shows its 1-based position in the current path.
/// - **Gray (dark)**   — blocked; permanently impassable, marked with an `xmark` icon.
struct StreaksCell: View, StreaksCellProtocol {
    var row: Int
    var column: Int
    var state: StreaksCellState

    init(row: Int, column: Int, state: StreaksCellState) {
        self.row = row
        self.column = column
        self.state = state
    }

    private var fillColor: Color {
        switch state {
        case .unselected: return Color(.systemGray5)
        case .selected:   return Color.accentColor
        case .blocked:    return Color(.systemGray2)
        }
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(fillColor)
            .overlay {
                switch state {
                case .selected(let order):
                    Text("\(order)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                case .blocked:
                    Image(systemName: "xmark")
                        .font(.caption.bold())
                        .foregroundStyle(Color(.systemGray4))
                default:
                    EmptyView()
                }
            }
            .animation(.easeInOut(duration: 0.12), value: state)
    }
}
