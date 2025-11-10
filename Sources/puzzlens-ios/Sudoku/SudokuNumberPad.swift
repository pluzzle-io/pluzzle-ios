import SwiftUI

public protocol InputPadCellProtocol: View {
    init(label: String, onTap: @escaping () -> Void)
}

struct SudokuNumberPad: View {
    var makeCell: (String, @escaping () -> Void) -> AnyView
    var onInput: (Int) -> Void
    var onClear: () -> Void
    
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
                        makeCell(label) { onInput(Int(label)!) }
                    }
                }
            }
        }
    }
}
