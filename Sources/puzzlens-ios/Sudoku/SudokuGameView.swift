import SwiftUI

// MARK: - Model

public struct SudokuGameModel {
    var grid: [[Int?]]
    var solution: [[Int]]
    
    @MainActor public static let example: SudokuGameModel = .init(
        grid: [
            [nil, 3, 4, 6, 7, 8, 9, 1, 2],
            [6, nil, 2, 1, 9, 5, 3, 4, 8],
            [1, 9, 8, 3, 4, 2, 5, 6, 7],
            
            [8, 5, 9, 7, 6, 1, 4, 2, 3],
            [4, 2, 6, 8, 5, 3, 7, 9, 1],
            [7, 1, 3, 9, 2, 4, 8, 5, 6],
            
            [9, 6, 1, 5, 3, 7, 2, 8, 4],
            [2, 8, 7, 4, 1, 9, 6, 3, 5],
            [3, 4, 5, 2, 8, 6, 1, 7, 9]
        ],
        solution: [
            [5, 3, 4, 6, 7, 8, 9, 1, 2],
            [6, 7, 2, 1, 9, 5, 3, 4, 8],
            [1, 9, 8, 3, 4, 2, 5, 6, 7],
            
            [8, 5, 9, 7, 6, 1, 4, 2, 3],
            [4, 2, 6, 8, 5, 3, 7, 9, 1],
            [7, 1, 3, 9, 2, 4, 8, 5, 6],
            
            [9, 6, 1, 5, 3, 7, 2, 8, 4],
            [2, 8, 7, 4, 1, 9, 6, 3, 5],
            [3, 4, 5, 2, 8, 6, 1, 7, 9]
        ]
    )
}

// MARK: - Protocols

public protocol InputPadCellProtocol: View {
    init(label: String, onTap: @escaping () -> Void)
}

public protocol SudokuCellProtocol: View {
    init(isSelected: Binding<Bool>, text: String, isFixed: Bool)
}

// MARK: - Default Cells

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

// MARK: - Example Custom Pad

struct MyInputPad: View, InputPadCellProtocol {
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

// MARK: - Number Pad (type-erased cell factory)

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

// MARK: - Game View (optional external reset trigger)

public struct SudokuGameView: View {
    // Config
    private var gridSpacing: CGFloat = 2.0

    // Optional external reset trigger (default nil)
    @Binding private var resetTrigger: Bool?

    // Selection
    @State private var selectedIndex: Int? = nil

    private let model: SudokuGameModel
    
    // Editable entries (nil means empty). Start with the initial grid.
    @State private var entries: [[Int?]] = []
    
    // MARK: - Init
    // If caller doesn't provide a binding, it defaults to `.constant(nil)`
    public init(model: SudokuGameModel, resetTrigger: Binding<Bool?> = .constant(nil)) {
        self.model = model
        self._resetTrigger = resetTrigger
    }
    
    private var n: Int { model.grid.count }
    private var m: Int { model.grid.first?.count ?? n }
    private var count: Int { n * m }
    
    // Type-erased factories (default implementations)
    private var cellFactory: (_ index: Int, _ isSelected: Binding<Bool>, _ text: String, _ isFixed: Bool) -> AnyView =
    { _, isSelected, text, isFixed in
        AnyView(SudokuGameCell(isSelected: isSelected, text: text, isFixed: isFixed))
    }

    private var inputPadFactory: (_ label: String, _ onTap: @escaping () -> Void) -> AnyView =
    { label, onTap in
        AnyView(SudokuInputPadCell(label: label, onTap: onTap))
    }

    // Callbacks
    private var onAppearCallback: (() -> Void)? = nil
    private var onDisappearCallback: (() -> Void)? = nil
    private var onInputCallback: ((_ row: Int, _ col: Int, _ value: Int?) -> Void)? = nil
    private var onCompletionCallback: ((Bool) -> Void)? = nil

    // n×m with matching H/V spacing
    var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: m)
    }
    
    // 3×3 overlay blocks (for 9×9)
    var overlayColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 0), count: 3)
    }

    public var body: some View {
        VStack(spacing: 12) {
            GeometryReader { gp in
                // Compute cell size accounting for spacing so grid fits width
                let totalHSpacing = gridSpacing * CGFloat(m - 1)
                let availableWidth = gp.size.width - totalHSpacing
                let cellSize = availableWidth / CGFloat(m)
                
                LazyVGrid(columns: columns, spacing: gridSpacing) {
                    ForEach(0..<count, id: \.self) { index in
                        let row = index / m
                        let col = index % m
                        let fixedValue = model.grid[row][col]
                        let isFixed = fixedValue != nil
                        
                        // show fixed value OR user entry
                        let displayValue = fixedValue ?? entries[safe: row]?[safe: col] ?? nil
                        let text = displayValue.map(String.init) ?? ""
                        
                        // isSelected binding derived from selectedIndex; blocked for fixed cells
                        let isSelected = Binding<Bool>(
                            get: { selectedIndex == index },
                            set: { newValue in
                                if !isFixed {
                                    selectedIndex = newValue ? index : nil
                                }
                            }
                        )

                        cellFactory(index, isSelected, text, isFixed)
                            .frame(width: cellSize, height: cellSize)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                guard !isFixed else { return }
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    selectedIndex = (selectedIndex == index) ? nil : index
                                }
                            }
                    }
                }
                // Thick 3×3 block borders overlay (only meaningful for 9×9)
                .overlay {
                    LazyVGrid(columns: overlayColumns, spacing: 0) {
                        ForEach(0..<9, id: \.self) { _ in
                            Rectangle()
                                .fill(.clear)
                                .frame(width: gp.size.width / 3, height: gp.size.width / 3)
                                .border(.black, width: 1.5)
                        }
                    }
                    .border(.black, width: 2)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .border(.black, width: 3)
            
            // Number Pad (factory-driven, no Clear)
            SudokuNumberPad(
                makeCell: inputPadFactory,
                onInput: { number in
                    guard let idx = selectedIndex else { return }
                    let row = idx / m
                    let col = idx % m
                    // Only allow editing non-fixed cells
                    if model.grid[row][col] == nil {
                        entries[row][col] = number
                        onInputCallback?(row, col, number)
                        if isGridFilled() {
                            onCompletionCallback?(isCompleteCorrectly())
                        }
                    }
                }
            )
        }
        .onAppear {
            if entries.isEmpty {
                entries = model.grid
            }
            onAppearCallback?()
        }
        .onDisappear {
            onDisappearCallback?()
        }
        // 🔁 External reset trigger (optional)
        .onChange(of: resetTrigger) { newValue in
            guard newValue == true else { return }
            resetGrid()
            // auto-clear the trigger so a subsequent `true` fires again
            resetTrigger = false
        }
    }

    // MARK: - Public helper (in-view direct call if needed)
    public func programmaticReset() {
        resetGrid()
    }

    // MARK: - Modifiers (generic API, type-erased storage)

    public func grid<T: SudokuCellProtocol>(spacing: CGFloat, cell: T.Type) -> Self {
        var copy = self
        copy.gridSpacing = spacing
        copy.cellFactory = { _, isSelected, text, isFixed in
            AnyView(T(isSelected: isSelected, text: text, isFixed: isFixed))
        }
        return copy
    }

    public func input<T: InputPadCellProtocol>(cell: T.Type) -> Self {
        var copy = self
        copy.inputPadFactory = { label, onTap in
            AnyView(T(label: label, onTap: onTap))
        }
        return copy
    }

    public func onAppear(_ handler: @escaping () -> Void) -> Self {
        var copy = self
        copy.onAppearCallback = handler
        return copy
    }

    public func onDisappear(_ handler: @escaping () -> Void) -> Self {
        var copy = self
        copy.onDisappearCallback = handler
        return copy
    }

    public func onInput(_ handler: @escaping (_ row: Int, _ col: Int, _ value: Int?) -> Void) -> Self {
        var copy = self
        copy.onInputCallback = handler
        return copy
    }

    public func onCompletion(_ handler: @escaping (Bool) -> Void) -> Self {
        var copy = self
        copy.onCompletionCallback = handler
        return copy
    }

    // MARK: - Helpers

    private func isGridFilled() -> Bool {
        for r in 0..<n {
            for c in 0..<m {
                if entries[r][c] == nil { return false }
            }
        }
        return true
    }

    private func isCompleteCorrectly() -> Bool {
        for r in 0..<n {
            for c in 0..<m {
                if entries[r][c] != model.solution[r][c] { return false }
            }
        }
        return true
    }
    
    private func resetGrid() {
        entries = model.grid
        selectedIndex = nil
    }
}

// MARK: - Safe Indexing

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview / Usage Examples

#Preview {
    VStack(spacing: 16) {
        // Example 1: No external reset (defaults to nil)
        SudokuGameView(model: .example)
            .grid(spacing: 1, cell: SudokuGameCell.self)
            .input(cell: MyInputPad.self)
    }
}
