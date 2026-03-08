import SwiftUI

struct SudokuGameCell: View, SudokuCellProtocol {
    @Binding var isSelected: Bool
    var text: String
    var isFixed: Bool

    var body: some View {
        Rectangle()
            .fill(isFixed ? .green : (isSelected ? .blue : .gray))
            .overlay(
                Text(text)
                    .font(.headline)
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
            )
    }
}
