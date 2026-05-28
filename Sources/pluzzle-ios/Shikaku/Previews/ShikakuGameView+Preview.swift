import SwiftUI

// MARK: - Default cell, all modifiers and callbacks

#Preview("Default — 9×6 example") {
    @Previewable @State var model = ShikakuModel.example
    ShikakuGameView(model: $model)
        .grid(spacing: 2, cell: ShikakuCell.self)
        .showViolations(true)
        .onMove { rect in
            print("Placed rect at (\(rect.row),\(rect.col)) \(rect.rowSpan)×\(rect.colSpan) area=\(rect.area)")
        }
        .onComplete {
            print("Puzzle solved!")
        }
        .padding()
}

// MARK: - Violations disabled

#Preview("Violations hidden") {
    @Previewable @State var model = ShikakuModel.example
    ShikakuGameView(model: $model)
        .grid(spacing: 2, cell: ShikakuCell.self)
        .showViolations(false)
        .padding()
}

// MARK: - Custom cell (demonstrates all ShikakuCellProtocol parameters)

private struct CustomShikakuCell: ShikakuCellProtocol {
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
            RoundedRectangle(cornerRadius: 4)
                .fill(background)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(state.isViolation ? Color.red : Color.clear, lineWidth: 2)
                )
            if state.isPreview {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.orange.opacity(0.3))
            }
            if let clue = state.clue {
                Text("\(clue)")
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundStyle(state.rect != nil ? Color.white : Color(.label))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .animation(.spring(response: 0.2), value: state)
    }

    private var background: Color {
        if state.isPreview { return Color.orange.opacity(0.15) }
        if state.rect != nil { return Color.teal.opacity(0.6) }
        return Color(.systemGray6)
    }
}

#Preview("Custom cell — teal/orange") {
    @Previewable @State var model = ShikakuModel.example
    ShikakuGameView(model: $model)
        .grid(spacing: 3, cell: CustomShikakuCell.self)
        .showViolations(true)
        .onMove { rect in
            print("Custom cell: placed \(rect.rowSpan)×\(rect.colSpan)")
        }
        .onComplete {
            print("Custom cell: solved!")
        }
        .padding()
}

// MARK: - Larger grid
//
// 7 rows × 9 cols = 63 cells. Verified solution:
//  col: 0 1 2 3 4 5 6 7 8
//  r 0: A A A A B B B C C
//  r 1: A A A A B B B C C
//  r 2: D D D D B B B C C
//  r 3: D D D D E E E E E
//  r 4: F F F F E E E E E
//  r 5: F F F F G G G H H
//  r 6: F F F F G G G H H
//
//  A=8  rows 0-1 cols 0-3   B=9  rows 0-2 cols 4-6
//  C=6  rows 0-2 cols 7-8   D=8  rows 2-3 cols 0-3
//  E=10 rows 3-4 cols 4-8   F=12 rows 4-6 cols 0-3
//  G=6  rows 5-6 cols 4-6   H=4  rows 5-6 cols 7-8

#Preview("Larger 7×9 grid") {
    @Previewable @State var model = ShikakuModel(
        rows: 7,
        columns: 9,
        clues: [
            ShikakuCoord(row: 0, col: 2):  8,  // A
            ShikakuCoord(row: 1, col: 5):  9,  // B
            ShikakuCoord(row: 2, col: 7):  6,  // C
            ShikakuCoord(row: 3, col: 1):  8,  // D
            ShikakuCoord(row: 4, col: 6): 10,  // E
            ShikakuCoord(row: 5, col: 2): 12,  // F
            ShikakuCoord(row: 6, col: 5):  6,  // G
            ShikakuCoord(row: 5, col: 8):  4,  // H
        ]
    )
    ShikakuGameView(model: $model)
        .grid(spacing: 2, cell: ShikakuCell.self)
        .showViolations(true)
        .onComplete {
            print("Large grid solved!")
        }
        .padding()
}
