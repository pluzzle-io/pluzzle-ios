# Voxel

Add a 3D Tic-Tac-Toe game to your app.

## Overview

`VoxelGameView` renders a 3D structure using SceneKit. Two players alternate tapping semi-transparent ghost cubes to attach their own cube to the structure. The first player to form `winLength` consecutive cubes in a straight line along any axis or diagonal wins. Drag anywhere to rotate the structure and inspect it from any angle.

### Getting started

```swift
import PuzzlensSDK

VoxelGameView()
    .onInput { coord, player in
        print("Player \(player) placed at (\(coord.x), \(coord.y), \(coord.z))")
    }
    .onCompletion { winner in
        print(winner != nil ? "Winner!" : "Draw")
    }
    .padding()
    .aspectRatio(1, contentMode: .fit)
```

### How the game works

1. The game begins with one neutral **seed cube** at the origin.
2. Semi-transparent **ghost cubes** mark every available face of the current structure.
3. **Player One** taps a ghost cube to place their cube there.
4. **Player Two** takes their turn.
5. Players alternate until one forms `winLength` consecutive cubes in a straight line.
6. Winning cubes are highlighted and `onCompletion` fires.
7. **Drag** to rotate the structure and view it from any angle.

---

## VoxelModel

```swift
public struct VoxelModel {
    public let winLength: Int
    public let maxTurns: Int

    public init(winLength: Int = 3, maxTurns: Int = 0)
}
```

| Property | Description |
|---|---|
| `winLength` | Number of consecutive same-player cubes required to win. Default: `3`. |
| `maxTurns` | Maximum total cubes placed before the game ends as a draw. `0` means no limit. |

---

## VoxelCoord

```swift
public struct VoxelCoord: Hashable, Equatable {
    public let x: Int
    public let y: Int
    public let z: Int

    public static let zero: VoxelCoord
    public var faceNeighbors: [VoxelCoord]   // 6 orthogonal neighbours
}
```

Identifies a cube's position in integer 3D space. The seed cube sits at `(0, 0, 0)`. Cubes can grow in any of the six axis-aligned directions.

---

## VoxelPlayer

```swift
public enum VoxelPlayer: Equatable {
    case one   // rendered in the theme's playerOne colour (default: blue)
    case two   // rendered in the theme's playerTwo colour (default: red)

    public var next: VoxelPlayer   // toggles between .one and .two
}
```

---

## Customising Node Shape — `.node(shape:size:)`

```swift
VoxelGameView()
    .node(shape: .box(chamfer: 0.15), size: 0.85)
```

| Parameter | Type | Description |
|---|---|---|
| `shape` | `VoxelNodeShape` | The geometry used for every node in the scene. |
| `size` | `CGFloat` | Bounding dimension of each node in scene units. Default: `0.9`. |

### VoxelNodeShape

```swift
public enum VoxelNodeShape {
    case box(chamfer: CGFloat = 0.1)   // rounded-corner box
    case sphere                         // perfect sphere
    case capsule                        // pill-shaped capsule
}
```

---

## Applying a Colour Theme — `.theme(_:)`

```swift
VoxelGameView()
    .theme(VoxelTheme(playerOne: .blue, playerTwo: .red, seed: .gray, ghost: .gray, win: .yellow))
```

### VoxelTheme

```swift
public struct VoxelTheme {
    public var playerOne: Color   // Player One cube colour. Default: .blue
    public var playerTwo: Color   // Player Two cube colour. Default: .red
    public var seed: Color        // Neutral seed cube colour.
    public var ghost: Color       // Placement hint (ghost) cube colour.
    public var win: Color         // Highlight colour for winning cubes.

    public static let `default`: VoxelTheme
}
```

---

## Win Directions

The engine checks all **13 unique straight-line directions** in 3D space:

| Category | Directions |
|---|---|
| Axes | +X, +Y, +Z |
| Face diagonals | XY, X−Y, XZ, X−Z, YZ, Y−Z |
| Space diagonals | XYZ, XY−Z, X−YZ, X−Y−Z |

---

## Callbacks

### `.onInput(_:)`

Called each time a player successfully places a cube.

```swift
VoxelGameView()
    .onInput { coord, player in
        let label = player == .one ? "Blue" : "Red"
        statusText = "\(label) placed at (\(coord.x), \(coord.y), \(coord.z))"
    }
```

| Parameter | Type | Description |
|---|---|---|
| `coord` | `VoxelCoord` | Position where the cube was placed. |
| `player` | `VoxelPlayer` | The player who placed it. |

### `.onCompletion(_:)`

Called when the game ends — either a win or a draw (when `maxTurns` is reached).

```swift
VoxelGameView()
    .onCompletion { winner in
        if let winner {
            alertMessage = (winner == .one ? "Blue" : "Red") + " wins!"
        } else {
            alertMessage = "It's a draw!"
        }
        showAlert = true
    }
```

| Parameter | Type | Description |
|---|---|---|
| `winner` | `VoxelPlayer?` | The winning player, or `nil` on a draw. |

---

## Putting It All Together

```swift
VoxelGameView(model: VoxelModel(winLength: 3, maxTurns: 0))
    .node(shape: .box(chamfer: 0.15), size: 0.85)
    .theme(VoxelTheme(playerOne: .indigo, playerTwo: .pink, seed: .gray, ghost: .gray, win: .yellow))
    .onInput { coord, player in
        let label = player == .one ? "Indigo" : "Pink"
        statusText = "\(label) placed at (\(coord.x), \(coord.y), \(coord.z))"
    }
    .onCompletion { winner in
        showAlert = true
        alertMessage = winner != nil ? "\(winner == .one ? "Indigo" : "Pink") wins!" : "It's a draw!"
    }
    .padding()
    .aspectRatio(1, contentMode: .fit)
    .background(Color(.systemGroupedBackground))
```
