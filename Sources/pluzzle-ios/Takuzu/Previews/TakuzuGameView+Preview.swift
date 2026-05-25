import SwiftUI

// MARK: - Default cell, all modifiers including hint

#Preview("Default — 6×6 example") {
    @Previewable @State var model = TakuzuModel.example
    @Previewable @State var hintCount = 0
    VStack(spacing: 16) {
        TakuzuGameView(model: $model)
            .grid(spacing: 4, cell: TakuzuCell.self)
            .showViolations(true)
            .hint(trigger: $hintCount)
            .onCellTap { row, col, value in
                print("Tapped (\(row),\(col)) → \(value.map { $0 ? "1" : "0" } ?? "empty")")
            }
            .onGameComplete { isCorrect in
                print(isCorrect ? "Solved correctly!" : "Board filled — incorrect.")
            }
            .aspectRatio(1, contentMode: .fit)
        Button("Hint (tapped \(hintCount)×)") { hintCount += 1 }
            .buttonStyle(.borderedProminent)
    }
    .padding()
}

// MARK: - Violations disabled

#Preview("Violations hidden") {
    @Previewable @State var model = TakuzuModel.example
    TakuzuGameView(model: $model)
        .grid(spacing: 4, cell: TakuzuCell.self)
        .showViolations(false)
        .padding()
        .aspectRatio(1, contentMode: .fit)
}

// MARK: - Custom cell (inline example demonstrating all modifier parameters)

private struct CustomTakuzuCell: TakuzuCellProtocol {
    let row: Int
    let column: Int
    let value: Bool?
    let isFixed: Bool
    let isViolation: Bool

    init(row: Int, column: Int, value: Bool?, isFixed: Bool, isViolation: Bool) {
        self.row = row; self.column = column
        self.value = value; self.isFixed = isFixed; self.isViolation = isViolation
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(bg)
                .overlay(Circle().strokeBorder(isViolation ? Color.red : Color.clear, lineWidth: 2))
            if let v = value {
                Text(v ? "■" : "○")
                    .font(.system(size: 16, weight: isFixed ? .black : .medium))
                    .foregroundStyle(isFixed ? Color.white : Color(.label))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .animation(.spring(response: 0.2), value: value)
    }

    private var bg: Color {
        if let v = value { return v ? .indigo : .teal }
        return Color(.systemGray5)
    }
}

#Preview("Custom cell — circles") {
    @Previewable @State var model = TakuzuModel.example
    TakuzuGameView(model: $model)
        .grid(spacing: 6, cell: CustomTakuzuCell.self)
        .showViolations(true)
        .onGameComplete { isCorrect in
            print(isCorrect ? "Custom cell — solved!" : "Custom cell — wrong.")
        }
        .padding()
        .aspectRatio(1, contentMode: .fit)
}

// MARK: - Larger grid (8×8)

#Preview("8×8 grid") {
    @Previewable @State var model = TakuzuModel(
        size: 8,
        cells: [
        /* r0 */ [true,  true,  nil,   nil,   nil,   nil,   nil,   false],
        /* r1 */ [nil,   true,  nil,   nil,   false, nil,   nil,   true ],
        /* r2 */ [nil,   false, true,  nil,   true,  nil,   nil,   nil  ],
        /* r3 */ [nil,   nil,   nil,   nil,   nil,   nil,   false, nil  ],
        /* r4 */ [false, nil,   nil,   false, nil,   nil,   nil,   true ],
        /* r5 */ [true,  nil,   true,  nil,   nil,   nil,   nil,   nil  ],
        /* r6 */ [nil,   nil,   nil,   nil,   false, nil,   true,  nil  ],
        /* r7 */ [nil,   nil,   nil,   nil,   true,  false, nil,   true ],
        ],
        solution: [
        /* r0 */ [true,  true,  false, false, true,  true,  false, false],
        /* r1 */ [false, true,  false, true,  false, false, true,  true ],
        /* r2 */ [true,  false, true,  false, true,  false, true,  false],
        /* r3 */ [false, false, true,  true,  false, true,  false, true ],
        /* r4 */ [false, true,  false, false, true,  true,  false, true ],
        /* r5 */ [true,  false, true,  true,  false, false, true,  false],
        /* r6 */ [true,  false, false, true,  false, true,  true,  false],
        /* r7 */ [false, true,  true,  false, true,  false, false, true ],
        ]
    )
    TakuzuGameView(model: $model)
        .grid(spacing: 3, cell: TakuzuCell.self)
        .showViolations(true)
        .padding()
        .aspectRatio(1, contentMode: .fit)
}
