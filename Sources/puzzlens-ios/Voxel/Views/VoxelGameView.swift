import SwiftUI
import SceneKit

// MARK: - Public API

/// A SwiftUI view that presents a Voxel puzzle — 3D Tic-Tac-Toe.
///
/// The game starts with a single neutral seed cube. Two players alternate
/// tapping any visible face of the structure to attach their own cube.
/// The first player to form `winLength` consecutive cubes in a straight
/// line (along any axis or diagonal in 3D space) wins.
/// Drag anywhere to rotate the structure.
public struct VoxelGameView: View {

    private let model: VoxelModel
    private var nodeShape: VoxelNodeShape = .box()
    private var nodeSize: CGFloat = 0.9
    private var theme: VoxelTheme = .default
    private var onInputCallback: ((_ coord: VoxelCoord, _ player: VoxelPlayer) -> Void)? = nil
    private var onCompletionCallback: ((_ winner: VoxelPlayer?) -> Void)? = nil

    public init(model: VoxelModel = VoxelModel()) {
        self.model = model
    }

    public var body: some View {
        _VoxelSceneRepresentable(
            model: model,
            nodeShape: nodeShape,
            nodeSize: nodeSize,
            theme: theme,
            onInput: onInputCallback,
            onCompletion: onCompletionCallback
        )
    }

    // MARK: - Modifiers

    /// Sets the shape and size used to render every node in the scene.
    /// - Parameters:
    ///   - shape: A `VoxelNodeShape` — `.box(chamfer:)`, `.sphere`, or `.capsule`.
    ///   - size: The bounding dimension of each node in scene units (default `0.9`).
    public func node(shape: VoxelNodeShape, size: CGFloat = 0.9) -> Self {
        var copy = self
        copy.nodeShape = shape
        copy.nodeSize = size
        return copy
    }

    /// Applies a colour theme to the scene.
    public func theme(_ theme: VoxelTheme) -> Self {
        var copy = self
        copy.theme = theme
        return copy
    }

    /// Called each time a player successfully places a node.
    /// - Parameter handler: Receives the placed coordinate and the player who placed it.
    public func onInput(_ handler: @escaping (_ coord: VoxelCoord, _ player: VoxelPlayer) -> Void) -> Self {
        var copy = self
        copy.onInputCallback = handler
        return copy
    }

    /// Called when the game ends — either by a win or by exhausting `maxTurns`.
    /// - Parameter handler: Receives the winning player, or `nil` on a draw.
    public func onCompletion(_ handler: @escaping (_ winner: VoxelPlayer?) -> Void) -> Self {
        var copy = self
        copy.onCompletionCallback = handler
        return copy
    }
}

// MARK: - UIViewRepresentable

private struct _VoxelSceneRepresentable: UIViewRepresentable {

    let model: VoxelModel
    var nodeShape: VoxelNodeShape
    var nodeSize: CGFloat
    var theme: VoxelTheme
    var onInput: ((VoxelCoord, VoxelPlayer) -> Void)?
    var onCompletion: ((VoxelPlayer?) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(model: model, nodeShape: nodeShape, nodeSize: nodeSize, theme: theme,
                    onInput: onInput, onCompletion: onCompletion)
    }

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = context.coordinator.scene
        scnView.allowsCameraControl = false
        scnView.antialiasingMode = .multisampling4X
        scnView.backgroundColor = .clear

        let pan = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        scnView.addGestureRecognizer(pan)

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        tap.require(toFail: pan)
        scnView.addGestureRecognizer(tap)

        context.coordinator.scnView = scnView
        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        let c = context.coordinator
        c.nodeShape = nodeShape
        c.nodeSize = nodeSize
        c.theme = theme
        c.onInput = onInput
        c.onCompletion = onCompletion
    }
}

// MARK: - Coordinator

extension _VoxelSceneRepresentable {

    @MainActor
    final class Coordinator: NSObject {

        // MARK: Scene

        let scene: SCNScene
        let gameRootNode: SCNNode
        let cameraNode: SCNNode
        weak var scnView: SCNView?

        // MARK: Config

        let model: VoxelModel
        var nodeShape: VoxelNodeShape
        var nodeSize: CGFloat
        var theme: VoxelTheme
        var onInput: ((VoxelCoord, VoxelPlayer) -> Void)?
        var onCompletion: ((VoxelPlayer?) -> Void)?

        // MARK: Game State

        var cells: [VoxelCoord: VoxelPlayer] = [:]
        var currentPlayer: VoxelPlayer = .one
        var winner: VoxelPlayer? = nil
        var isGameOver: Bool {
            winner != nil || (model.maxTurns > 0 && cells.count >= model.maxTurns)
        }

        // MARK: Node Tracking

        var cubeNodes: [VoxelCoord: SCNNode] = [:]
        var ghostNodes: [VoxelCoord: SCNNode] = [:]

        // MARK: Rotation State

        var rotationX: Float = 0.4
        var rotationY: Float = 0.5
        var lastPanLocation: CGPoint = .zero

        // MARK: Init

        init(model: VoxelModel,
             nodeShape: VoxelNodeShape,
             nodeSize: CGFloat,
             theme: VoxelTheme,
             onInput: ((VoxelCoord, VoxelPlayer) -> Void)?,
             onCompletion: ((VoxelPlayer?) -> Void)?) {
            self.model = model
            self.nodeShape = nodeShape
            self.nodeSize = nodeSize
            self.theme = theme
            self.onInput = onInput
            self.onCompletion = onCompletion
            self.scene = SCNScene()
            self.gameRootNode = SCNNode()
            self.cameraNode = SCNNode()
            super.init()
            setupScene()
        }

        // MARK: - Scene Setup

        private func setupScene() {
            cameraNode.camera = SCNCamera()
            cameraNode.camera?.fieldOfView = 50
            cameraNode.position = SCNVector3(0, 0, 10)
            scene.rootNode.addChildNode(cameraNode)

            let ambientNode = SCNNode()
            ambientNode.light = SCNLight()
            ambientNode.light?.type = .ambient
            ambientNode.light?.intensity = 600
            scene.rootNode.addChildNode(ambientNode)

            let dirNode = SCNNode()
            dirNode.light = SCNLight()
            dirNode.light?.type = .directional
            dirNode.light?.intensity = 800
            dirNode.eulerAngles = SCNVector3(-Float.pi / 4, Float.pi / 4, 0)
            scene.rootNode.addChildNode(dirNode)

            gameRootNode.eulerAngles = SCNVector3(rotationX, rotationY, 0)
            scene.rootNode.addChildNode(gameRootNode)

            let seedNode = makeSolidNode(color: color(for: .one))
            seedNode.name = "seed"
            gameRootNode.addChildNode(seedNode)
            cells[.zero] = .one
            cubeNodes[.zero] = seedNode

            refreshGhostNodes()
        }

        // MARK: - Node Factories

        private func makeGeometry() -> SCNGeometry {
            let s = nodeSize
            switch nodeShape {
            case .box(let chamfer):
                return SCNBox(width: s, height: s, length: s, chamferRadius: chamfer)
            case .sphere:
                return SCNSphere(radius: s / 2)
            case .capsule:
                let capRadius = s * 0.3
                return SCNCapsule(capRadius: capRadius, height: s - capRadius)
            }
        }

        private func makeSolidNode(color: UIColor) -> SCNNode {
            let geo = makeGeometry()
            let mat = SCNMaterial()
            mat.lightingModel = .lambert
            mat.diffuse.contents = color
            geo.materials = [mat]
            return SCNNode(geometry: geo)
        }

        private func makeGhostNode() -> SCNNode {
            let geo = makeGeometry()
            let mat = SCNMaterial()
            mat.lightingModel = .constant
            mat.diffuse.contents = UIColor(theme.ghost)
            mat.fillMode = .lines
            mat.isDoubleSided = true
            geo.materials = [mat]
            return SCNNode(geometry: geo)
        }

        private func color(for player: VoxelPlayer) -> UIColor {
            UIColor(player == .one ? theme.playerOne : theme.playerTwo)
        }

        // MARK: - Ghost Management

        private func refreshGhostNodes() {
            for node in ghostNodes.values { node.removeFromParentNode() }
            ghostNodes = [:]

            guard !isGameOver else { return }

            let origins: Set<VoxelCoord> = cells.isEmpty ? [.zero] : Set(cells.keys)
            var available = Set<VoxelCoord>()
            for coord in origins {
                for neighbor in coord.faceNeighbors where cells[neighbor] == nil {
                    available.insert(neighbor)
                }
            }

            for coord in available {
                let node = makeGhostNode()
                node.position = SCNVector3(Float(coord.x), Float(coord.y), Float(coord.z))
                node.name = "ghost_\(coord.x)_\(coord.y)_\(coord.z)"
                gameRootNode.addChildNode(node)
                ghostNodes[coord] = node
            }
        }

        // MARK: - Camera

        private func updateCamera() {
            var sumX: Float = 0, sumY: Float = 0, sumZ: Float = 0
            let count = Float(cells.count)
            for coord in cells.keys {
                sumX += Float(coord.x); sumY += Float(coord.y); sumZ += Float(coord.z)
            }
            let cx = sumX / count, cy = sumY / count, cz = sumZ / count

            // Bounding-sphere radius: farthest cube center from centroid + node half-extent + padding
            var maxR: Float = 0
            for coord in cells.keys {
                let dx = Float(coord.x) - cx
                let dy = Float(coord.y) - cy
                let dz = Float(coord.z) - cz
                maxR = max(maxR, sqrt(dx*dx + dy*dy + dz*dz))
            }
            let radius = maxR + Float(nodeSize) * 0.5 + 1.0

            let halfFOV = Float(25.0 * .pi / 180.0)
            let required = radius / tan(halfFOV)
            let newZ = max(cameraNode.position.z, required)

            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.4
            // Track centroid in X/Y so the entire structure stays centered on screen
            cameraNode.position = SCNVector3(cx, cy, newZ)
            SCNTransaction.commit()
        }

        // MARK: - Rotation Center

        private func updateRotationCenter() {
            var sumX: Float = 0, sumY: Float = 0, sumZ: Float = 0
            let count = Float(cells.count)
            for coord in cells.keys {
                sumX += Float(coord.x)
                sumY += Float(coord.y)
                sumZ += Float(coord.z)
            }
            let cx = sumX / count
            let cy = sumY / count
            let cz = sumZ / count

            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.3
            gameRootNode.pivot = SCNMatrix4MakeTranslation(cx, cy, cz)
            gameRootNode.position = SCNVector3(cx, cy, cz)
            SCNTransaction.commit()
        }

        // MARK: - Placement

        private func placePlayerCube(at coord: VoxelCoord) {
            let player = currentPlayer
            cells[coord] = player

            ghostNodes[coord]?.removeFromParentNode()
            ghostNodes.removeValue(forKey: coord)

            let node = makeSolidNode(color: color(for: player))
            node.position = SCNVector3(Float(coord.x), Float(coord.y), Float(coord.z))
            node.scale = SCNVector3(0.01, 0.01, 0.01)
            gameRootNode.addChildNode(node)
            cubeNodes[coord] = node
            node.runAction(.scale(to: 1.0, duration: 0.15))

            updateRotationCenter()
            updateCamera()
            onInput?(coord, player)

            if let winLine = checkWin(for: player, at: coord) {
                winner = player
                clearGhosts()
                highlightWinningNodes(winLine)
                onCompletion?(player)
            } else if model.maxTurns > 0 && cells.count >= model.maxTurns {
                clearGhosts()
                onCompletion?(nil)
            } else {
                currentPlayer = player.next
                refreshGhostNodes()
            }
        }

        private func clearGhosts() {
            for node in ghostNodes.values { node.removeFromParentNode() }
            ghostNodes = [:]
        }

        // MARK: - Win Detection

        private func checkWin(for player: VoxelPlayer, at coord: VoxelCoord) -> [VoxelCoord]? {
            let directions: [(Int, Int, Int)] = [
                (1, 0, 0), (0, 1, 0), (0, 0, 1),
                (1, 1, 0), (1, -1, 0),
                (1, 0, 1), (1, 0, -1),
                (0, 1, 1), (0, 1, -1),
                (1, 1, 1), (1, 1, -1), (1, -1, 1), (1, -1, -1),
            ]
            for dir in directions {
                var line = [coord]
                var c = VoxelCoord(x: coord.x + dir.0, y: coord.y + dir.1, z: coord.z + dir.2)
                while cells[c] == player { line.append(c); c = VoxelCoord(x: c.x + dir.0, y: c.y + dir.1, z: c.z + dir.2) }
                c = VoxelCoord(x: coord.x - dir.0, y: coord.y - dir.1, z: coord.z - dir.2)
                while cells[c] == player { line.append(c); c = VoxelCoord(x: c.x - dir.0, y: c.y - dir.1, z: c.z - dir.2) }
                if line.count >= model.winLength { return line }
            }
            return nil
        }

        private func highlightWinningNodes(_ coords: [VoxelCoord]) {
            let mat = SCNMaterial()
            mat.lightingModel = .lambert
            mat.diffuse.contents = UIColor(theme.win)
            for coord in coords {
                cubeNodes[coord]?.geometry?.materials = [mat]
            }
        }

        // MARK: - Gesture Handling

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            let loc = gesture.translation(in: gesture.view)
            if gesture.state == .began { lastPanLocation = loc }

            let dx = Float(loc.x - lastPanLocation.x) * 0.012
            let dy = Float(loc.y - lastPanLocation.y) * 0.012
            lastPanLocation = loc

            rotationY += dx
            rotationX = max(-.pi / 2, min(.pi / 2, rotationX + dy))
            gameRootNode.eulerAngles = SCNVector3(rotationX, rotationY, 0)
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard !isGameOver, let scnView = scnView else { return }
            let location = gesture.location(in: scnView)

            let hits = scnView.hitTest(location, options: [
                SCNHitTestOption.searchMode: SCNHitTestSearchMode.all.rawValue,
            ])

            for hit in hits {
                guard let name = hit.node.name, name.hasPrefix("ghost_") else { continue }
                let parts = name.dropFirst("ghost_".count).split(separator: "_")
                guard parts.count == 3,
                      let x = Int(parts[0]), let y = Int(parts[1]), let z = Int(parts[2])
                else { continue }
                placePlayerCube(at: VoxelCoord(x: x, y: y, z: z))
                return
            }
        }
    }
}
