import SwiftUI

struct SudokuInputPad: View, InputPadCellProtocol {
    var label: String
    var onTap: () -> Void

    init(label: String, onTap: @escaping () -> Void) {
        self.label = label
        self.onTap = onTap
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(.indigo)
                .shadow(radius: 1, x: 0, y: 1)
            Text(label)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.vertical, 10)
        }
        .onTapGesture { onTap() }
        .frame(height: 50)
    }
}
