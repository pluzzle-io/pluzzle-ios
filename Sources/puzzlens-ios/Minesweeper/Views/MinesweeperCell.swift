import SwiftUI

/// The default cell view used by ``MinesweeperGameView``.
///
/// Renders each ``MinesweeperCellState`` with classic Minesweeper conventions:
/// - **Hidden** — solid gray tile.
/// - **Revealed(0)** — flat empty tile (no number).
/// - **Revealed(1–8)** — flat tile with the adjacent-mine count in its classic colour (blue, green, red, …).
/// - **Flagged** — gray tile with an orange flag icon.
/// - **Exploded** — red tile with a danger icon (the mine the player tapped).
/// - **Mine revealed** — muted tile with an outline danger icon (other mines shown at game over).
public struct MinesweeperCell: MinesweeperCellProtocol {
    public let row: Int
    public let column: Int
    public let state: MinesweeperCellState

    public init(row: Int, column: Int, state: MinesweeperCellState) {
        self.row = row
        self.column = column
        self.state = state
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
            content
        }
        .aspectRatio(1, contentMode: .fit)
        .animation(.easeInOut(duration: 0.1), value: state)
    }

    private var backgroundColor: Color {
        switch state {
        case .hidden, .flagged:      return Color(.systemGray4)
        case .revealed:              return Color(.systemGray6)
        case .exploded:              return .red
        case .mineRevealed:          return Color(.systemGray3)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .hidden:
            EmptyView()
        case .revealed(let count):
            if count > 0 {
                Text("\(count)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(numberColor(for: count))
            }
        case .flagged:
            Image(systemName: "flag.fill")
                .foregroundStyle(.orange)
                .font(.system(size: 11, weight: .bold))
        case .exploded:
            Image(systemName: "xmark.octagon.fill")
                .foregroundStyle(.white)
                .font(.system(size: 13, weight: .bold))
        case .mineRevealed:
            Image(systemName: "xmark.octagon")
                .foregroundStyle(Color(.label))
                .font(.system(size: 11))
        }
    }

    /// Classic Minesweeper number colours (1 = blue … 8 = gray).
    private func numberColor(for count: Int) -> Color {
        switch count {
        case 1: return .blue
        case 2: return .green
        case 3: return .red
        case 4: return Color(red: 0.0, green: 0.0, blue: 0.55)
        case 5: return Color(red: 0.55, green: 0.0, blue: 0.0)
        case 6: return .cyan
        case 7: return Color(.label)
        default: return Color(.systemGray)
        }
    }
}
