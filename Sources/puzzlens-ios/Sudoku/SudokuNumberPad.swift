import SwiftUI

struct SudokuNumberPad: View {
    var makeCell: (String, @escaping () -> Void) -> AnyView
    var onInput: (Int) -> Void
    
    private let rows: [[String]] = [
        ["1","2","3"],
        ["4","5","6"],
        ["7","8","9"]
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<rows.count, id: \.self) { r in
                HStack(spacing: 8) {
                    ForEach(rows[r], id: \.self) { label in
                        makeCell(label) {
                            onInput(Int(label)!)
                        }
                    }
                }
            }
        }
    }
}

public protocol InputPadCellProtocol: View {
    init(label: String, onTap: @escaping () -> Void)
}

struct SudokuInputPadCell: View, InputPadCellProtocol {
    var label: String
    var onTap: () -> Void

    init(label: String, onTap: @escaping () -> Void) {
        self.label = label
        self.onTap = onTap
    }

    var body: some View {
        Rectangle()
            .fill(.blue)
            .overlay(
                Text(label)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
            )
            .onTapGesture { onTap() }
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
