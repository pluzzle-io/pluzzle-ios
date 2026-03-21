# Streaks

Add a continuous-path drawing puzzle to your app.

## Overview

`StreaksGameView` presents an N×M grid where the player drags a single continuous path through every non-blocked cell. The path accumulates as the player drags; lifting a finger mid-puzzle resets it silently. When every cell has been visited the puzzle completes.

### Getting started

```swift
import PluzzleSDK

StreaksGameView(model: StreaksModel(rows: 5, columns: 5))
    .grid(spacing: 8, cell: MyCustomCell.self)
    .onInput { path in print("Path length: \(path.count)") }
    .onCompletion { _ in print("Puzzle solved!") }
    .padding()
    .aspectRatio(1, contentMode: .fit)
```

### How the game works

1. The player places a finger anywhere on the grid to begin.
2. Dragging moves the path to adjacent cells — both **orthogonal** and **diagonal** movement is allowed.
3. Each cell can only be visited **once**.
4. Lifting the finger before every cell is visited **resets** the path automatically.
5. When every required cell has been visited `onCompletion` fires.

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
| `blockedCells` | Cells that cannot be visited and do not count toward completion. |
| `totalCells` | Number of cells the player must connect (total minus blocked). |

### Adding blocked cells

Blocked cells act as impassable obstacles. It is the developer's responsibility to ensure the remaining cells form a fully connectable path.

```swift
let model = StreaksModel(
    rows: 5, columns: 5,
    blockedCells: [
        StreaksCoord(row: 1, col: 1),
        StreaksCoord(row: 1, col: 3),
        StreaksCoord(row: 3, col: 1),
        StreaksCoord(row: 3, col: 3),
    ]
)
```

### StreaksCoord

```swift
public struct StreaksCoord: Hashable, Equatable {
    public let row: Int   // zero-based
    public let col: Int   // zero-based
}
```

---

## StreaksCellState

```swift
public enum StreaksCellState: Equatable, Hashable {
    case unselected
    case selected(order: Int)
    case blocked
}
```

| Case | Description |
|---|---|
| `.unselected` | Not yet visited in the current path. |
| `.selected(order:)` | Visited. `order` is the 1-based position in the path. |
| `.blocked` | An obstacle — cannot be visited, not counted toward completion. |

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

### StreaksCellProtocol

```swift
public protocol StreaksCellProtocol: View {
    init(row: Int, column: Int, state: StreaksCellState)
}
```

| Parameter | Type | Description |
|---|---|---|
| `row` | `Int` | Zero-based row index. |
| `column` | `Int` | Zero-based column index. |
| `state` | `StreaksCellState` | Current cell state. |

### Example custom cell

```swift
struct MyCustomCell: View, StreaksCellProtocol {
    var row: Int
    var column: Int
    var state: StreaksCellState

    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(background)
            .overlay {
                if case .selected(let order) = state {
                    Text("\(order)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                }
            }
    }

    private var background: Color {
        switch state {
        case .unselected: return Color.gray.opacity(0.2)
        case .selected:   return Color.indigo
        case .blocked:    return Color.gray.opacity(0.05)
        }
    }
}
```

---

## Callbacks

### `.onInput(_:)`

Called each time the player extends the path by one cell.

```swift
StreaksGameView(model: model)
    .onInput { path in
        triggerSelectionHaptic()
    }
```

| Parameter | Type | Description |
|---|---|---|
| `path` | `[(row: Int, col: Int)]` | The ordered list of all visited cells, newest last. |

### `.onCompletion(_:)`

Called when every required cell has been visited.

```swift
StreaksGameView(model: model)
    .onCompletion { _ in
        showSuccessBanner = true
    }
```

| Parameter | Type | Description |
|---|---|---|
| `didWin` | `Bool` | Always `true` — fires only on successful completion. |

> Lifting the finger mid-path resets the puzzle silently without firing `onCompletion`.

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
