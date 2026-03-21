# VoxelGameView

`VoxelGameView` presents a 3D Tic-Tac-Toe puzzle rendered with SceneKit. Two players alternate attaching cubes to a growing structure until one forms `winLength` consecutive cubes along any axis or diagonal in 3D space.

---

## Overview

```swift
import PluzzleSDK

VoxelGameView(model: VoxelModel(winLength: 3))
    .onInput { coord, player in
        print("\(player) placed at (\(coord.x), \(coord.y), \(coord.z))")
    }
    .onCompletion { winner in
        print("\(winner) wins!")
    }
```

---

## How the game works

1. The game begins with one neutral seed cube at the origin.
2. Semi-transparent ghost cubes mark every available face of the current structure.
3. **Player One (blue)** taps a ghost cube to place their cube there.
4. **Player Two (red)** takes their turn.
5. Players alternate until one forms `winLength` consecutive cubes in a straight line — along the X, Y, or Z axis, or along any face or space diagonal.
6. The winning cubes are highlighted and `onCompletion` fires.
7. **Drag** anywhere on the view to rotate the entire structure and inspect it from any angle.

---

## VoxelModel

```swift
public struct VoxelModel {
    public let winLength: Int
    public init(winLength: Int = 3)
}
```

| Property | Description |
|---|---|
| `winLength` | Number of consecutive same-player cubes required to win. Default: `3`. |

---

## VoxelCoord

```swift
public struct VoxelCoord: Hashable, Equatable {
    public let x: Int
    public let y: Int
    public let z: Int
}
```

Identifies a cube's position in integer 3D space. The seed cube sits at `(0, 0, 0)`. Cubes can extend in any of the six axis-aligned directions.

---

## VoxelPlayer

```swift
public enum VoxelPlayer: Equatable {
    case one   // rendered in blue
    case two   // rendered in red
}
```

---

## Callbacks

### `.onInput(_:)`

Called each time a player successfully places a cube.

```swift
VoxelGameView(model: model)
    .onInput { coord, player in
        triggerHaptic()
    }
```

| Parameter | Type | Description |
|---|---|---|
| `coord` | `VoxelCoord` | Position where the cube was placed. |
| `player` | `VoxelPlayer` | The player who placed it. |

### `.onCompletion(_:)`

Called when a player forms a winning line.

```swift
VoxelGameView(model: model)
    .onCompletion { winner in
        showWinnerBanner(for: winner)
    }
```

| Parameter | Type | Description |
|---|---|---|
| `winner` | `VoxelPlayer` | The player who won. |

---

## Win directions

The engine checks all **13 unique straight-line directions** in 3D space:

| Category | Directions |
|---|---|
| Axes | +X, +Y, +Z |
| Face diagonals | XY, X−Y, XZ, X−Z, YZ, Y−Z |
| Space diagonals | XYZ, XY−Z, X−YZ, X−Y−Z |

---

## Putting It All Together

```swift
VoxelGameView(model: VoxelModel(winLength: 3))
    .onInput { coord, player in
        let label = player == .one ? "Blue" : "Red"
        statusText = "\(label) placed at (\(coord.x), \(coord.y), \(coord.z))"
    }
    .onCompletion { winner in
        let label = winner == .one ? "Blue" : "Red"
        showAlert = true
        alertMessage = "\(label) wins!"
    }
    .aspectRatio(1, contentMode: .fit)
    .background(Color(.systemGroupedBackground))
```
