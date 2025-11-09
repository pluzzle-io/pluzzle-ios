//
//  SwiftUIView.swift
//  PuzzlensSDK
//
//  Created by Usman N on 09/11/2025.
//

import SwiftUI

struct CellConfig {
    // Colors
    var backgroundColor: Color
    var selectedColor: Color
    var disabledColor: Color
    var textColor: Color
    var selectedTextColor: Color
    var disabledTextColor: Color
    
    // Fonts
    var font: Font
    var selectedFont: Font

    // Other
    var cornerRadius: CGFloat
}

struct GridConfig {
    var spacing: CGFloat
}

struct SudokuGameView: View {
    
    private var cellConfig: CellConfig = .init(backgroundColor: .blue, selectedColor: .green, disabledColor: .gray, textColor: .black, selectedTextColor: .white, disabledTextColor: .red, font: .body, selectedFont: .body, cornerRadius: 10)
    
    private var gridConfig: GridConfig = GridConfig(spacing: 16)
    
    var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: gridConfig.spacing), count: 3)
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: gridConfig.spacing) {
            ForEach(0..<9) { index in
                Rectangle()
                    .fill(cellConfig.backgroundColor)
                    .frame(height: 100)
                    .overlay(
                        Text("\(index + 1)")
                            .foregroundColor(cellConfig.textColor)
                    )
                    .cornerRadius(cellConfig.cornerRadius)
            }
        }
        .padding()
        .onAppear {
            print("Rendered puzzle")
        }
    }
    
    func cell(_ config: CellConfig) -> SudokuGameView {
        var copy = self
        copy.cellConfig = config
        return copy
    }
    
    func grid(_ config: GridConfig) -> SudokuGameView {
        var copy = self
        copy.gridConfig = config
        return copy
    }
}

#Preview {
    VStack {
        SudokuGameView()
            .cell(
                .init(backgroundColor: .blue, selectedColor: .green, disabledColor: .gray, textColor: .black, selectedTextColor: .white, disabledTextColor: .red, font: .body, selectedFont: .body, cornerRadius: 10)
            )
        
        SudokuGameView()
            .grid(.init(spacing: 2))
            .cell(
                .init(backgroundColor: .green, selectedColor: .green, disabledColor: .gray, textColor: .white, selectedTextColor: .white, disabledTextColor: .red, font: .body, selectedFont: .body, cornerRadius: 10)
            )
    }
}
