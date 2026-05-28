import SwiftUI

// MARK: - Default cell, all modifiers and callbacks

#Preview("Default — 5×7 example") {
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

#Preview("Larger 7×9 grid") {
    @Previewable @State var model = ShikakuModel(
        rows: 7,
        columns: 9,
        clues: [
            ShikakuCoord(row: 0, col: 0): 3,
            ShikakuCoord(row: 0, col: 4): 4,
            ShikakuCoord(row: 0, col: 8): 6,
            ShikakuCoord(row: 2, col: 2): 2,
            ShikakuCoord(row: 2, col: 6): 4,
            ShikakuCoord(row: 3, col: 0): 7,
            ShikakuCoord(row: 4, col: 4): 3,
            ShikakuCoord(row: 4, col: 8): 2,
            ShikakuCoord(row: 6, col: 1): 6,
            ShikakuCoord(row: 6, col: 6): 26,
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
