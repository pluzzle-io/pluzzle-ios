import Foundation

/// A position in 3D integer space used to identify a Voxel cube.
public struct VoxelCoord: Hashable, Equatable, Sendable {
    public let x: Int
    public let y: Int
    public let z: Int

    public static let zero = VoxelCoord(x: 0, y: 0, z: 0)

    public init(x: Int, y: Int, z: Int) {
        self.x = x
        self.y = y
        self.z = z
    }

    /// The six face-adjacent neighbours (orthogonal only).
    var faceNeighbors: [VoxelCoord] {
        [
            VoxelCoord(x: x + 1, y: y,     z: z),
            VoxelCoord(x: x - 1, y: y,     z: z),
            VoxelCoord(x: x,     y: y + 1, z: z),
            VoxelCoord(x: x,     y: y - 1, z: z),
            VoxelCoord(x: x,     y: y,     z: z + 1),
            VoxelCoord(x: x,     y: y,     z: z - 1),
        ]
    }
}
