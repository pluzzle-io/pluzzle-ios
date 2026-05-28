import SwiftUI

// MARK: - Default cell, all modifiers and callbacks

#Preview("Default — 6×9 example") {
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
// 8 rows × 12 cols = 96 cells (3:2 ratio). Verified solution:
//  col: 0  1  2  3  4  5  6  7  8  9  10 11
//  r 0: A  A  A  B  B  B  C  C  D  D  D  D
//  r 1: A  A  A  B  B  B  C  C  D  D  D  D
//  r 2: A  A  A  E  E  F  F  F  G  G  G  G
//  r 3: H  H  H  E  E  F  F  F  G  G  G  G
//  r 4: H  H  H  I  I  I  J  J  J  K  K  K
//  r 5: H  H  H  I  I  I  J  J  J  K  K  K
//  r 6: L  L  L  L  M  M  M  N  N  N  O  O
//  r 7: L  L  L  L  M  M  M  N  N  N  O  O
//
//  A=9  rows 0-2 cols 0-2   B=6  rows 0-1 cols 3-5
//  C=4  rows 0-1 cols 6-7   D=8  rows 0-1 cols 8-11
//  E=4  rows 2-3 cols 3-4   F=6  rows 2-3 cols 5-7
//  G=8  rows 2-3 cols 8-11  H=9  rows 3-5 cols 0-2
//  I=6  rows 4-5 cols 3-5   J=6  rows 4-5 cols 6-8
//  K=6  rows 4-5 cols 9-11  L=8  rows 6-7 cols 0-3
//  M=6  rows 6-7 cols 4-6   N=6  rows 6-7 cols 7-9
//  O=4  rows 6-7 cols 10-11

#Preview("Larger 8×12 grid") {
    @Previewable @State var model = ShikakuModel(
        rows: 8,
        columns: 12,
        clues: [
            ShikakuCoord(row: 1, col: 1):  9,  // A
            ShikakuCoord(row: 0, col: 4):  6,  // B
            ShikakuCoord(row: 1, col: 6):  4,  // C
            ShikakuCoord(row: 0, col: 10): 8,  // D
            ShikakuCoord(row: 2, col: 3):  4,  // E
            ShikakuCoord(row: 3, col: 6):  6,  // F
            ShikakuCoord(row: 2, col: 9):  8,  // G
            ShikakuCoord(row: 4, col: 1):  9,  // H
            ShikakuCoord(row: 5, col: 4):  6,  // I
            ShikakuCoord(row: 4, col: 7):  6,  // J
            ShikakuCoord(row: 5, col: 10): 6,  // K
            ShikakuCoord(row: 6, col: 2):  8,  // L
            ShikakuCoord(row: 7, col: 5):  6,  // M
            ShikakuCoord(row: 6, col: 8):  6,  // N
            ShikakuCoord(row: 7, col: 10): 4,  // O
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
