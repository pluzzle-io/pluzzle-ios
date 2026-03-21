# Sudoku

Add a fully interactive 9×9 Sudoku puzzle to your app.

## Overview

`SudokuGameView` renders a 9×9 grid with a number pad below it. Fixed cells (pre-filled by the puzzle) are locked. The player selects an empty cell and taps a number pad button to fill it. The view detects when every cell is filled and reports whether the solution is correct.

### Getting started

```swift
import PluzzleSDK

SudokuGameView(model: SudokuGameModel.example)
    .padding()
```

### How the game works

1. The player taps an empty cell to select it. Fixed cells cannot be selected.
2. The player taps a number on the input pad to fill the selected cell.
3. Tapping the same number again clears the cell.
4. When every cell is filled `onCompletion` fires, passing `true` if the grid matches the solution.

---

## SudokuGameModel

```swift
public struct SudokuGameModel {
    public let grid: [[Int?]]
    public let solution: [[Int]]

    public init(grid: [[Int?]], solution: [[Int]])
}
```

| Property | Description |
|---|---|
| `grid` | The puzzle's starting state — `Int` for pre-filled cells, `nil` for empty cells. |
| `solution` | The complete, correct 9×9 solution grid. |

```swift
let model = SudokuGameModel(
    grid: [
        [nil, 3, 4, 6, 7, 8, 9, 1, 2],
        [6, 7, 2, 1, 9, 5, 3, 4, 8],
        // ...
    ],
    solution: [
        [5, 3, 4, 6, 7, 8, 9, 1, 2],
        [6, 7, 2, 1, 9, 5, 3, 4, 8],
        // ...
    ]
)
```

---

## External Reset

Pass a `Binding<Bool?>` to trigger a puzzle reset from outside the view. Set it to `true` to reset; the view resets it back to `nil` automatically so subsequent resets work correctly.

```swift
@State private var resetTrigger: Bool? = nil

var body: some View {
    VStack {
        SudokuGameView(model: model, resetTrigger: $resetTrigger)

        Button("Restart") {
            resetTrigger = true
        }
    }
}
```

---

## Customising Grid Cells — `.grid(spacing:cell:)`

```swift
SudokuGameView(model: model)
    .grid(spacing: 1, cell: MyCustomCell.self)
```

| Parameter | Type | Description |
|---|---|---|
| `spacing` | `CGFloat` | Gap between cells in points. |
| `cell` | `T.Type` | A type conforming to `SudokuCellProtocol`. |

### SudokuCellProtocol

```swift
public protocol SudokuCellProtocol: View {
    init(isSelected: Binding<Bool>, text: String, isFixed: Bool)
}
```

| Parameter | Type | Description |
|---|---|---|
| `isSelected` | `Binding<Bool>` | Whether this cell is currently selected. |
| `text` | `String` | The digit to display (`"1"`–`"9"`), or an empty string when blank. |
| `isFixed` | `Bool` | `true` if the cell was pre-filled and cannot be edited. |

### Example custom cell

```swift
struct MyCustomCell: View, SudokuCellProtocol {
    @Binding var isSelected: Bool
    var text: String
    var isFixed: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(isFixed ? Color.primary.opacity(0.1) : (isSelected ? Color.accentColor : .clear))
                .border(Color.secondary.opacity(0.3), width: 0.5)

            Text(text)
                .font(.title2.bold())
                .foregroundStyle(isFixed ? .primary : (isSelected ? .white : .primary))
        }
    }
}
```

---

## Customising the Input Pad — `.input(cell:)`

```swift
SudokuGameView(model: model)
    .input(cell: MyCustomPadButton.self)
```

### InputPadCellProtocol

```swift
public protocol InputPadCellProtocol: View {
    init(label: String, onTap: @escaping () -> Void)
}
```

| Parameter | Type | Description |
|---|---|---|
| `label` | `String` | The digit label (`"1"`–`"9"`). |
| `onTap` | `() -> Void` | Call this when the button is tapped. |

### Example custom pad button

```swift
struct MyCustomPadButton: View, InputPadCellProtocol {
    var label: String
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
```

---

## Callbacks

### `.onInput(_:)`

Called every time the player fills a cell.

```swift
SudokuGameView(model: model)
    .onInput { row, col, value in
        print("Entered \(value ?? 0) at row \(row), col \(col)")
    }
```

| Parameter | Type | Description |
|---|---|---|
| `row` | `Int` | Zero-based row index of the edited cell. |
| `col` | `Int` | Zero-based column index of the edited cell. |
| `value` | `Int?` | The digit entered (1–9), or `nil` if the cell was cleared. |

### `.onCompletion(_:)`

Called when the player has filled every cell.

```swift
SudokuGameView(model: model)
    .onCompletion { isCorrect in
        alertMessage = isCorrect ? "Puzzle solved!" : "Grid full but incorrect."
        showAlert = true
    }
```

| Parameter | Type | Description |
|---|---|---|
| `isCorrect` | `Bool` | `true` if the filled grid matches the solution; `false` otherwise. |

---

## Putting It All Together

```swift
@State private var resetTrigger: Bool? = nil

SudokuGameView(model: model, resetTrigger: $resetTrigger)
    .grid(spacing: 1, cell: MyCustomCell.self)
    .input(cell: MyCustomPadButton.self)
    .onInput { row, col, value in
        print("Entered \(value ?? 0) at (\(row), \(col))")
    }
    .onCompletion { isCorrect in
        showAlert = true
        alertMessage = isCorrect ? "Well done!" : "Not quite right."
    }
```
