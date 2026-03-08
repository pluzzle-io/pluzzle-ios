import SwiftUI

public protocol SudokuCellProtocol: View {
    init(isSelected: Binding<Bool>, text: String, isFixed: Bool)
}
