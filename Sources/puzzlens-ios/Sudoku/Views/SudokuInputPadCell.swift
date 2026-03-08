import SwiftUI

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
