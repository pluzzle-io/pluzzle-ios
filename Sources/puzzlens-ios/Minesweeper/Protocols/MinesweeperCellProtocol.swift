import SwiftUI

public protocol MinesweeperCellProtocol: View {
    init(row: Int, column: Int, state: MinesweeperCellState)
}
