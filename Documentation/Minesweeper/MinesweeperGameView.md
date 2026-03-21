# MinesweeperGameView

`MinesweeperGameView` is a self-contained SwiftUI view that renders a fully interactive Minesweeper game. The player taps cells to reveal them and long-presses to plant flags. Hidden mines can be pre-placed or auto-generated on the first tap. The view handles flood-fill reveal, scoring, and game-over detection out of the box. Its appearance can be customised through a chainable modifier API.

---

## Basic Usage

At minimum, provide a `MinesweeperModel` that describes the grid size and mine count:

```swift
import PluzzleSDK

let model = MinesweeperModel(rows: 9, columns: 9, mineCount: 10)

var body: some View {
    MinesweeperGameView(model: model)
}
```

### How the game works

1. The player **taps** a hidden cell to reveal it.
2. If the revealed cell has **zero adjacent mines**, it flood-fills outward — revealing all connected zero-adjacent cells and their numbered borders automatically.
3. If the revealed cell has **one or more adjacent mines**, only that cell is revealed and its count is shown.
4. The player can **long-press** a hidden cell to plant a flag marking a suspected mine. Long-pressing again removes the flag.
5. Flagged cells **cannot be revealed by tap** — the player must remove the flag first.
6. **Scoring:** each safely revealed cell awards one point. The cumulative score is reported through `.onInput(_:)`.
7. The game ends when:
   - All safe cells have been revealed → **win** (`onCompletion(true)`).
   - The player taps a mine → **loss** (`onCompletion(false)`), all remaining mines are exposed.

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
| `mineCount` | How many mines to place when auto-generating. Ignored if `mines` is non-empty. |
| `mines` | Optional pre-placed mine coordinates. Leave empty for a safe auto-generated start. |

### Auto-generated mines (safe start)

When `mines` is empty the view generates mine positions on the player's **first tap**, ensuring that cell and all its immediate neighbors are mine-free — making it impossible to lose on the opening move.

```swift
// Beginner — 9×9, 10 mines, safe first tap
let model = MinesweeperModel(rows: 9, columns: 9, mineCount: 10)

// Intermediate — 16×16, 40 mines
let model = MinesweeperModel(rows: 16, columns: 16, mineCount: 40)

// Expert — 16×30, 99 mines
let model = MinesweeperModel(rows: 16, columns: 30, mineCount: 99)
```

### Pre-placed mines

Pass a `Set<MinesweeperCoord>` to control the mine layout exactly — useful for puzzles, tutorials, or reproducible test cases. `mineCount` is ignored when `mines` is non-empty.

```swift
let model = MinesweeperModel(
    rows: 5,
    columns: 5,
    mineCount: 0,   // ignored
    mines: [
        MinesweeperCoord(row: 0, col: 2),
        MinesweeperCoord(row: 2, col: 0),
        MinesweeperCoord(row: 4, col: 4),
    ]
)
```

### MinesweeperCoord

A zero-based row/column coordinate identifying a single cell.

```swift
public struct MinesweeperCoord: Hashable, Equatable {
    public let row: Int   // zero-based, top = 0
    public let col: Int   // zero-based, left = 0
}
```

---

## MinesweeperCellState

Each cell is rendered according to its current `MinesweeperCellState`:

```swift
public enum MinesweeperCellState: Equatable, Hashable {
    case hidden
    case revealed(adjacentMines: Int)
    case flagged
    case exploded
    case mineRevealed
}
```

| Case | When | Default appearance |
|---|---|---|
| `.hidden` | Not yet revealed or flagged. | Solid gray tile. |
| `.revealed(adjacentMines:)` | Safely uncovered. `adjacentMines` is 0–8. | Flat tile; blank if 0, otherwise the count in its classic colour. |
| `.flagged` | Player long-pressed to mark a suspected mine. | Gray tile with orange flag icon. |
| `.exploded` | The player tapped this mine — game over. | Red tile with filled danger icon. |
| `.mineRevealed` | Another mine exposed automatically at game over. | Muted gray tile with outline danger icon. |

---

## Customising Grid Cells — `.grid(spacing:cell:)`

```swift
MinesweeperGameView(model: model)
    .grid(spacing: 4, cell: MyCustomCell.self)
```

| Parameter | Type | Description |
|---|---|---|
| `spacing` | `CGFloat` | Gap between cells in points. |
| `cell` | `T.Type` | A type conforming to `MinesweeperCellProtocol`. |

### Adopting `MinesweeperCellProtocol`

```swift
public protocol MinesweeperCellProtocol: View {
    init(row: Int, column: Int, state: MinesweeperCellState)
}
```

| Parameter | Type | Description |
|---|---|---|
| `row` | `Int` | Zero-based row index of the cell. |
| `column` | `Int` | Zero-based column index of the cell. |
| `state` | `MinesweeperCellState` | Current state determining how the cell should be drawn. |

**Example custom cell:**

```swift
struct MyCell: View, MinesweeperCellProtocol {
    let row: Int
    let column: Int
    let state: MinesweeperCellState

    init(row: Int, column: Int, state: MinesweeperCellState) {
        self.row = row; self.column = column; self.state = state
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(background)
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

Called each time a safe cell is revealed — including every cell uncovered during a flood-fill expansion. Use this to react to individual reveals, trigger haptics, or update a score display.

```swift
MinesweeperGameView(model: model)
    .onInput { coord, score in
        print("Revealed (\(coord.row), \(coord.col)) — total score: \(score)")
    }
```

| Parameter | Type | Description |
|---|---|---|
| `coord` | `MinesweeperCoord` | The coordinate of the cell that was just revealed. |
| `score` | `Int` | Cumulative count of safely revealed cells so far. |

> **Note:** When a single tap triggers a flood-fill, `onInput` fires once per revealed cell in BFS order. The `score` value increases by 1 with each call.

### `.onCompletion(_:)`

Called once when the game ends — either all safe cells revealed (win) or a mine tapped (loss).

```swift
MinesweeperGameView(model: model)
    .onCompletion { didWin in
        if didWin {
            print("Board cleared! Final score: \(score)")
        } else {
            print("Boom! Game over.")
        }
    }
```

| Parameter | Type | Description |
|---|---|---|
| `didWin` | `Bool` | `true` if all safe cells were revealed; `false` if a mine was hit. |

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
        resultMessage = didWin
            ? "You cleared the board!"
            : "Better luck next time."
    }
    .padding()
    .aspectRatio(CGFloat(9) / CGFloat(9), contentMode: .fit)
```
