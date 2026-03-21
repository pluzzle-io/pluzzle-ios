# StreaksGameView

`StreaksGameView` presents an N×M grid puzzle where the player must drag a single continuous path through every cell.

---

## Overview

```swift
import PluzzleSDK

let model = StreaksModel(rows: 5, columns: 5)

StreaksGameView(model: model)
    .grid(spacing: 8, cell: StreaksCell.self)
    .onInput { path in
        print("Cells visited: \(path.count)")
    }
    .onCompletion { _ in
        print("Puzzle solved!")
    }
    .padding()
    .aspectRatio(1, contentMode: .fit)
```

---

## How the game works

1. The player places a finger anywhere on the grid to begin.
2. Dragging moves the path to adjacent cells (orthogonal and diagonal).
3. Each cell can only be visited **once**.
4. If the finger is lifted before every cell is visited the path **resets** automatically.
5. When every cell has been visited the puzzle is complete and `onCompletion` fires.

---

## StreaksModel

```swift
public struct StreaksModel {
    public let rows: Int
    public let columns: Int
    public let blockedCells: Set<StreaksCoord>
    public var totalCells: Int { rows * columns - blockedCells.count }

    public init(rows: Int, columns: Int, blockedCells: Set<StreaksCoord> = [])
}
```

| Property | Description |
|---|---|
| `rows` | Number of rows in the grid. |
| `columns` | Number of columns in the grid. |
| `blockedCells` | Set of coordinates that cannot be visited and do not count toward completion. |
| `totalCells` | Cells the player must connect — total minus blocked. |

### Blocked cells

Pass a `Set<StreaksCoord>` to mark cells as impassable obstacles:

```swift
let model = StreaksModel(
    rows: 5,
    columns: 5,
    blockedCells: [
        StreaksCoord(row: 1, col: 1),
        StreaksCoord(row: 1, col: 3),
        StreaksCoord(row: 3, col: 1),
        StreaksCoord(row: 3, col: 3)
    ]
)
```

Blocked cells are rendered by `StreaksCellProtocol` with state `.blocked`, are skipped during drag, and never counted toward completion. It is the developer's responsibility to ensure the remaining cells form a fully connectable path.

---

## Customising Grid Cells — `.grid(spacing:cell:)`

```swift
StreaksGameView(model: model)
    .grid(spacing: 8, cell: MyCustomCell.self)
```

| Parameter | Type | Description |
|---|---|---|
| `spacing` | `CGFloat` | Gap between cells in points. |
| `cell` | `T.Type` | A type conforming to `StreaksCellProtocol`. |

### Adopting `StreaksCellProtocol`

```swift
public protocol StreaksCellProtocol: View {
    init(row: Int, column: Int, state: StreaksCellState)
}
```

| Parameter | Type | Description |
|---|---|---|
| `row` | `Int` | Zero-based row index. |
| `column` | `Int` | Zero-based column index. |
| `state` | `StreaksCellState` | `.unselected` or `.selected(order:)`. |

### StreaksCellState

```swift
public enum StreaksCellState: Equatable, Hashable {
    case unselected
    case selected(order: Int)
}
```

| Case | Description |
|---|---|
| `.unselected` | The cell has not been visited. |
| `.selected(order:)` | Visited; `order` is the 1-based position in the current path. |
| `.blocked` | The cell is an obstacle — cannot be visited, not counted toward completion. |

**Example custom cell:**

```swift
struct MyCustomCell: View, StreaksCellProtocol {
    var row: Int
    var column: Int
    var state: StreaksCellState

    init(row: Int, column: Int, state: StreaksCellState) {
        self.row = row
        self.column = column
        self.state = state
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(state == .unselected ? Color.gray.opacity(0.2) : Color.indigo)
            .overlay {
                if case .selected(let order) = state {
                    Text("\(order)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                }
            }
    }
}
```

---

## Callbacks

### `.onInput(_:)`

Called each time the player adds a new cell to the path.

```swift
StreaksGameView(model: model)
    .onInput { path in
        print("Current path length: \(path.count)")
    }
```

| Parameter | Type | Description |
|---|---|---|
| `path` | `[(row: Int, col: Int)]` | The ordered path of visited cells, including the newest. |

### `.onCompletion(_:)`

Called when the player successfully connects every cell in the grid.

```swift
StreaksGameView(model: model)
    .onCompletion { didWin in
        showAlert = true
    }
```

| Parameter | Type | Description |
|---|---|---|
| `didWin` | `Bool` | Always `true` — fires only on successful completion. |

> **Note:** When the player lifts their finger mid-path the view resets silently without firing `onCompletion`.

---

## Putting It All Together

```swift
StreaksGameView(model: StreaksModel(rows: 4, columns: 6))
    .grid(spacing: 10, cell: MyCustomCell.self)
    .onInput { path in
        triggerHaptic()
    }
    .onCompletion { _ in
        showSuccessBanner = true
    }
    .padding()
    .aspectRatio(CGFloat(6) / CGFloat(4), contentMode: .fit)
```
