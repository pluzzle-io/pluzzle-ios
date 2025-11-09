import SwiftUI

protocol SudokuCellProtocol: View {
    init(isSelected: Binding<Bool>, text: String)
}

struct SudokuGameCell: View, SudokuCellProtocol {
    @Binding var isSelected: Bool
    var text: String

    var body: some View {
        Rectangle()
            .fill(isSelected ? .blue : .red)
            .frame(height: 50)
            .overlay(Text(text).foregroundColor(.white))
            .cornerRadius(10)
    }
}

struct GridConfig { var spacing: CGFloat }

struct SudokuGameView: View {
    // Config
    private var gridConfig: GridConfig = .init(spacing: 16)
    private var count: Int = 9

    // Selection: only one at a time
    @State private var selectedIndex: Int? = nil

    // Type-erased factory (defaults to SudokuGameCell)
    private var cellFactory: (Int, Binding<Bool>) -> AnyView = { index, isSelected in
        AnyView(SudokuGameCell(isSelected: isSelected, text: "\(index + 1)"))
    }

    // 3x3 with matching H/V spacing
    var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: gridConfig.spacing), count: 3)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: gridConfig.spacing) {
            ForEach(0..<count, id: \.self) { index in
                // Bind 'isSelected' to the single selectedIndex
                let isSelected = Binding<Bool>(
                    get: { selectedIndex == index },
                    set: { newValue in
                        selectedIndex = newValue ? index : nil
                    }
                )

                cellFactory(index, isSelected)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Toggle with single-selection semantics
                        selectedIndex = (selectedIndex == index) ? nil : index
                    }
            }
        }
        .onAppear {
            print("Puzzle rendered")
        }
        .padding()
    }

    // MARK: - Modifiers

    func grid(_ config: GridConfig) -> Self {
        var copy = self
        copy.gridConfig = config
        return copy
    }

    // API: SudokuGameView().cell(SudokuGameCell.self)
    func cell<T: SudokuCellProtocol>(_ type: T.Type) -> Self {
        var copy = self
        copy.cellFactory = { index, isSelected in
            AnyView(T(isSelected: isSelected, text: "\(index + 1)"))
        }
        return copy
    }

    // Optional: set number of cells (e.g., 81 for 9x9)
    func count(_ n: Int) -> Self {
        var copy = self
        copy.count = n
        // Reset selection when count changes
        copy._selectedIndex = State(initialValue: nil)
        return copy
    }
}

#Preview {
    VStack(spacing: 24) {
        SudokuGameView() // default cell type

        SudokuGameView()
            .cell(SudokuGameCell.self)
            .grid(.init(spacing: 8))
    }
}
