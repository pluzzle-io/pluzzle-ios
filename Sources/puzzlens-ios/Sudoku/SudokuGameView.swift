import SwiftUI

// MARK: - Model

struct SudokuGameModel {
    var grid: [[Int?]] // 9x9 grid. Nil represents empty space
    var solution: [[Int]] // 9x9 grid with solution
    
    static let example: SudokuGameModel = .init(
        grid: [
            [5, 3, nil, nil, 7, nil, nil, nil, nil],
            [6, nil, nil, 1, 9, 5, nil, nil, nil],
            [nil, 9, 8, nil, nil, nil, nil, 6, nil],
            
            [8, nil, nil, nil, 6, nil, nil, nil, 3],
            [4, nil, nil, 8, nil, 3, nil, nil, 1],
            [7, nil, nil, nil, 2, nil, nil, nil, 6],
            
            [nil, 6, nil, nil, nil, nil, 2, 8, nil],
            [nil, nil, nil, 4, 1, 9, nil, nil, 5],
            [nil, nil, nil, nil, 8, nil, nil, 7, 9]
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

protocol SudokuCellProtocol: View {
    init(isSelected: Binding<Bool>, text: String, isFixed: Bool)
}

// MARK: - Default Cell

struct SudokuGameCell: View, SudokuCellProtocol {
    @Binding var isSelected: Bool
    var text: String
    var isFixed: Bool

    var body: some View {
        Rectangle()
            .fill(isFixed ? .red : (isSelected ? .blue : .gray))
            .overlay(
                Text(text)
                    .font(.headline)
                    .foregroundColor(.white)
            )
    }
}

// MARK: - Number Pad

struct SudokuNumberPad: View {
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
                        Button(action: { onInput(Int(label)!) }) {
                            Text(label)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            Button(role: .destructive, action: onClear) {
                Text("Clear")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
        }
    }
}

// MARK: - Grid View

struct SudokuGameView: View {
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

    // n×m with matching H/V spacing
    var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: m)
    }
    
    // 3×3 overlay blocks (for 9×9)
    var overlayColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 0), count: 3)
    }

    var body: some View {
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
                    if n == 9 && m == 9 {
                        LazyVGrid(columns: overlayColumns, spacing: 0) {
                            ForEach(0..<9, id: \.self) { _ in
                                Rectangle()
                                    .fill(.clear)
                                    .frame(width: gp.size.width / 3, height: gp.size.width / 3)
                                    .border(.black, width: 2)
                            }
                        }
                        .border(.black, width: 2)
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit) // Keep grid square
            
            // Number Pad
            SudokuNumberPad(
                onInput: { number in
                    guard let idx = selectedIndex else { return }
                    let row = idx / m
                    let col = idx % m
                    // Only allow editing non-fixed cells
                    if model.grid[row][col] == nil {
                        entries[row][col] = number
                    }
                },
                onClear: {
                    guard let idx = selectedIndex else { return }
                    let row = idx / m
                    let col = idx % m
                    if model.grid[row][col] == nil {
                        entries[row][col] = nil
                    }
                }
            )
        }
        .onAppear {
            // initialize entries with the starting grid (nil where empty)
            if entries.isEmpty {
                entries = model.grid
            }
        }
    }

    // MARK: - Modifiers

    func grid<T: SudokuCellProtocol>(_ spacing: CGFloat, _ cell: T.Type) -> Self {
        var copy = self
        copy.gridSpacing = spacing
        copy.cellFactory = { _, isSelected, text, isFixed in
            AnyView(T(isSelected: isSelected, text: text, isFixed: isFixed))
        }
        return copy
    }

    // API: SudokuGameView(model: .example).cell(SudokuGameCell.self)
    func cell<T: SudokuCellProtocol>(_ type: T.Type) -> Self {
        var copy = self
        copy.cellFactory = { _, isSelected, text, isFixed in
            AnyView(T(isSelected: isSelected, text: text, isFixed: isFixed))
        }
        return copy
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
            .grid(2, SudokuGameCell.self)
            .padding()
    }
}
