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

// MARK: - Cell Protocol

public protocol SudokuCellProtocol: View {
    init(isSelected: Binding<Bool>, text: String, isFixed: Bool)
}

// MARK: - Default Input Pad Cell (matches SudokuGameCell vibe)

struct SudokuInputPadCell: View, InputPadCellProtocol {
    var label: String
    var onTap: () -> Void

    init(label: String, onTap: @escaping () -> Void) {
        self.label = label
        self.onTap = onTap
    }

    var body: some View {
        Rectangle()
            .fill(label == "Clear" ? .red.opacity(0.85) : .blue)
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

// MARK: - Example Custom Input Pad Cell (for .input(MyInputPad.self))

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
                .fill(label == "Clear" ? .black.opacity(0.8) : .indigo)
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

// MARK: - Grid View

public struct SudokuGameView: View {
    // Config
    private var gridSpacing: CGFloat = 2.0

    // Selection: only one at a time
    @State private var selectedIndex: Int? = nil

    private let model: SudokuGameModel
    
    // Editable entries (nil means empty). Start with the initial grid.
    @State private var entries: [[Int?]] = []
    
    init(model: SudokuGameModel) {
        self.model = model
        // entries will be initialized in .onAppear to avoid State-before-init warnings
    }
    
    private var n: Int { model.grid.count }                                  // 9
    private var m: Int { model.grid.first?.count ?? n }                      // 9
    private var count: Int { n * m }                                         // 81
    
    // Type-erased factory (default to SudokuGameCell)
    private var cellFactory: (_ index: Int, _ isSelected: Binding<Bool>, _ text: String, _ isFixed: Bool) -> AnyView =
    { _, isSelected, text, isFixed in
        AnyView(SudokuGameCell(isSelected: isSelected, text: text, isFixed: isFixed))
    }

    // Input pad type-erased factory (default to SudokuInputPadCell)
    private var inputPadFactory: (_ label: String, _ onTap: @escaping () -> Void) -> AnyView =
    { label, onTap in
        AnyView(SudokuInputPadCell(label: label, onTap: onTap))
    }

    // DELEGATE-LIKE CALLBACKS
    private var onAppearCallback: (() -> Void)? = nil
    private var onDisappearCallback: (() -> Void)? = nil
    private var onInputCallback: ((_ row: Int, _ col: Int, _ value: Int?) -> Void)? = nil
    private var onCompletionCallback: ((Bool) -> Void)? = nil  // ← now reports success/failure

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
                                guard !isFixed else { return } // ignore taps on fixed cells
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
            
            // Number Pad (factory-driven)
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
                        // Only fire completion when grid is fully filled; then pass correctness
                        if isGridFilled() {
                            onCompletionCallback?(isCompleteCorrectly())
                        }
                    }
                },
                onClear: {
                    guard let idx = selectedIndex else { return }
                    let row = idx / m
                    let col = idx % m
                    if model.grid[row][col] == nil {
                        entries[row][col] = nil
                        onInputCallback?(row, col, nil)
                        // Do not call completion here; grid isn't full anymore
                    }
                }
            )
        }
        .onAppear {
            // initialize entries with the starting grid (nil where empty)
            if entries.isEmpty {
                entries = model.grid
            }
            onAppearCallback?()
        }
        .onDisappear {
            onDisappearCallback?()
        }
    }

    // MARK: - Modifiers

    func grid<T: SudokuCellProtocol>(spacing: CGFloat, cell: T.Type) -> Self {
        var copy = self
        copy.gridSpacing = spacing
        copy.cellFactory = { _, isSelected, text, isFixed in
            AnyView(T(isSelected: isSelected, text: text, isFixed: isFixed))
        }
        return copy
    }

    // API: .input(MyInputPad.self)
    func input<T: InputPadCellProtocol>(cell: T.Type) -> Self {
        var copy = self
        copy.inputPadFactory = { label, onTap in
            AnyView(T(label: label, onTap: onTap))
        }
        return copy
    }

    // Delegates-style callbacks
    func onAppear(_ handler: @escaping () -> Void) -> Self {
        var copy = self
        copy.onAppearCallback = handler
        return copy
    }

    func onDisappear(_ handler: @escaping () -> Void) -> Self {
        var copy = self
        copy.onDisappearCallback = handler
        return copy
    }

    func onInput(_ handler: @escaping (_ row: Int, _ col: Int, _ value: Int?) -> Void) -> Self {
        var copy = self
        copy.onInputCallback = handler
        return copy
    }

    func onCompletion(_ handler: @escaping (Bool) -> Void) -> Self {
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
}

// MARK: - Safe Indexing Helper

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview

#Preview {
    VStack {
        SudokuGameView(model: .example)
            .grid(spacing: 1, cell: SudokuGameCell.self)
            .input(cell: MyInputPad.self)
            .onAppear { print("🔵 appear") }
            .onDisappear { print("🟠 disappear") }
            .onInput { r, c, v in print("✏️ input (\(r),\(c)) =", v as Any) }
            .onCompletion { success in
                print(success ? "✅ completed (correct)" : "❌ completed (incorrect)")
            }
            .padding()
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
