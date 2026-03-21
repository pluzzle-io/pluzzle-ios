# Minesweeper

Add a fully interactive Minesweeper game to your app.

## Overview

`MinesweeperGameView` renders a grid of hidden cells. The player taps to reveal cells and long-presses to plant flags. The view handles flood-fill reveal, mine auto-generation with a guaranteed safe first tap, and game-over detection out of the box.

### Getting started

```swift
import PluzzleSDK

MinesweeperGameView(model: MinesweeperModel(rows: 9, columns: 9, mineCount: 10))
    .padding()
```

### How the game works

1. The player **taps** a hidden cell to reveal it.
2. If the revealed cell has **zero adjacent mines** the view flood-fills outward, revealing all connected zero-count cells and their numbered borders automatically.
3. If the cell has **one or more adjacent mines** only that cell is revealed and its count is shown.
4. The player **long-presses** a hidden cell to place a flag. Long-pressing again removes it. Flagged cells cannot be tapped.
5. **Scoring** — each safely revealed cell awards one point, reported through `.onInput`.
6. The game ends when all safe cells are revealed (**win**) or the player taps a mine (**loss**).

---

## MinesweeperModel

```swift
public struct MinesweeperModel {
    public let rows: Int
    public let columns: Int
    public let mineCount: Int
    public let mines: Set<MinesweeperCoord>

    public init(rows: Int, columns: Int, mineCount: Int, mines: Set<MinesweeperCoord> = [])
}
```

| Property | Description |
|---|---|
| `rows` | Number of rows in the grid. |
| `columns` | Number of columns in the grid. |
| `mineCount` | Mines to generate on first tap. Ignored when `mines` is non-empty. |
| `mines` | Optional pre-placed mine coordinates for reproducible puzzles. |

### Preset difficulty levels

```swift
// Beginner
MinesweeperModel(rows: 9,  columns: 9,  mineCount: 10)

// Intermediate
MinesweeperModel(rows: 16, columns: 16, mineCount: 40)

// Expert
MinesweeperModel(rows: 16, columns: 30, mineCount: 99)
```

### Pre-placing mines

```swift
let model = MinesweeperModel(
    rows: 5, columns: 5, mineCount: 0,
    mines: [
        MinesweeperCoord(row: 0, col: 2),
        MinesweeperCoord(row: 2, col: 0),
        MinesweeperCoord(row: 4, col: 4),
    ]
)
```

### MinesweeperCoord

```swift
public struct MinesweeperCoord: Hashable, Equatable {
    public let row: Int   // zero-based, top = 0
    public let col: Int   // zero-based, left = 0
}
```

---

## MinesweeperCellState

Each cell is rendered according to its current state:

```swift
public enum MinesweeperCellState: Equatable, Hashable {
    case hidden
    case revealed(adjacentMines: Int)
    case flagged
    case exploded
    case mineRevealed
}
```

| Case | When shown |
|---|---|
| `.hidden` | Not yet revealed or flagged. |
| `.revealed(adjacentMines:)` | Safely uncovered. `adjacentMines` is 0–8. |
| `.flagged` | Player long-pressed to mark a suspected mine. |
| `.exploded` | The player tapped a mine — game over. |
| `.mineRevealed` | Another mine exposed automatically at game over. |

---

## Customising Cells — `.grid(spacing:cell:)`

```swift
MinesweeperGameView(model: model)
    .grid(spacing: 4, cell: MyCell.self)
```

| Parameter | Type | Description |
|---|---|---|
| `spacing` | `CGFloat` | Gap between cells in points. |
| `cell` | `T.Type` | A type conforming to `MinesweeperCellProtocol`. |

### MinesweeperCellProtocol

```swift
public protocol MinesweeperCellProtocol: View {
    init(row: Int, column: Int, state: MinesweeperCellState)
}
```

### Example custom cell

```swift
struct MyCell: View, MinesweeperCellProtocol {
    let row: Int
    let column: Int
    let state: MinesweeperCellState

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8).fill(background)
            label
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var background: Color {
        switch state {
        case .hidden, .flagged:  return Color(.systemGray5)
        case .revealed:          return Color(.systemGray6)
        case .exploded:          return .red.opacity(0.8)
        case .mineRevealed:      return Color(.systemGray4)
        }
    }

    @ViewBuilder
    private var label: some View {
        switch state {
        case .revealed(let n) where n > 0:
            Text("\(n)").font(.caption.bold())
        case .flagged:
            Image(systemName: "flag.fill").foregroundStyle(.orange)
        case .exploded, .mineRevealed:
            Image(systemName: "xmark.circle.fill").foregroundStyle(.white)
        default:
            EmptyView()
        }
    }
}
```

---

## Callbacks

### `.onInput(_:)`

Called each time a safe cell is revealed — including every cell uncovered during flood-fill.

```swift
MinesweeperGameView(model: model)
    .onInput { coord, score in
        print("Revealed (\(coord.row), \(coord.col)) — score: \(score)")
    }
```

| Parameter | Type | Description |
|---|---|---|
| `coord` | `MinesweeperCoord` | The coordinate just revealed. |
| `score` | `Int` | Cumulative count of safely revealed cells. |

> When a single tap triggers flood-fill, `onInput` fires once per revealed cell in BFS order. The score increases by 1 with each call.

### `.onCompletion(_:)`

Called once when the game ends.

```swift
MinesweeperGameView(model: model)
    .onCompletion { didWin in
        print(didWin ? "Board cleared!" : "Boom!")
    }
```

| Parameter | Type | Description |
|---|---|---|
| `didWin` | `Bool` | `true` if all safe cells were revealed; `false` if a mine was tapped. |

---

## Putting It All Together

```swift
MinesweeperGameView(model: MinesweeperModel(rows: 9, columns: 9, mineCount: 10))
    .grid(spacing: 4, cell: MyCell.self)
    .onInput { coord, score in
        triggerSelectionHaptic()
    }
    .onCompletion { didWin in
        showResult = true
        resultMessage = didWin ? "Board cleared!" : "Better luck next time."
    }
    .padding()
    .aspectRatio(1, contentMode: .fit)
```
