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
// 12 rows × 8 cols = 96 cells (2:3 portrait ratio). Verified solution:
//  col: 0 1 2 3 4 5 6 7
//  r 0: A A A B B C C C    A(6)  rows  0-1 cols 0-2
//  r 1: A A A B B C C C    B(4)  rows  0-1 cols 3-4
//  r 2: D D D D E E E E    C(6)  rows  0-1 cols 5-7
//  r 3: D D D D E E E E    D(8)  rows  2-3 cols 0-3
//  r 4: F F G G H H I I    E(8)  rows  2-3 cols 4-7
//  r 5: F F G G H H I I    F(4)  rows  4-5 cols 0-1
//  r 6: J J J J K K K K    G(4)  rows  4-5 cols 2-3
//  r 7: J J J J K K K K    H(4)  rows  4-5 cols 4-5
//  r 8: L L M M N N N N    I(4)  rows  4-5 cols 6-7
//  r 9: L L M M N N N N    J(8)  rows  6-7 cols 0-3
// r10: O O O O P P P P    K(8)  rows  6-7 cols 4-7
// r11: O O O O P P P P    L(4)  rows  8-9 cols 0-1
//                           M(4)  rows  8-9 cols 2-3
//                           N(8)  rows  8-9 cols 4-7
//                           O(8)  rows 10-11 cols 0-3
//                           P(8)  rows 10-11 cols 4-7

#Preview("Larger 12×8 grid") {
    @Previewable @State var model = ShikakuModel(
        rows: 12,
        columns: 8,
        clues: [
            ShikakuCoord(row: 0, col: 1):  6,  // A
            ShikakuCoord(row: 1, col: 3):  4,  // B
            ShikakuCoord(row: 0, col: 6):  6,  // C
            ShikakuCoord(row: 2, col: 2):  8,  // D
            ShikakuCoord(row: 3, col: 6):  8,  // E
            ShikakuCoord(row: 4, col: 0):  4,  // F
            ShikakuCoord(row: 5, col: 2):  4,  // G
            ShikakuCoord(row: 4, col: 5):  4,  // H
            ShikakuCoord(row: 5, col: 7):  4,  // I
            ShikakuCoord(row: 6, col: 1):  8,  // J
            ShikakuCoord(row: 7, col: 6):  8,  // K
            ShikakuCoord(row: 8, col: 0):  4,  // L
            ShikakuCoord(row: 9, col: 3):  4,  // M
            ShikakuCoord(row: 8, col: 5):  8,  // N
            ShikakuCoord(row: 10, col: 2): 8,  // O
            ShikakuCoord(row: 11, col: 5): 8,  // P
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
