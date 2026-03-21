import Foundation

/// A position in 3D integer space used to identify a Voxel cube.
///
/// Coordinates use a right-handed axis system where `x` is right, `y` is up, and `z` is toward the viewer.
public struct VoxelCoord: Hashable, Equatable, Sendable {
    /// X-axis coordinate.
    public let x: Int
    /// Y-axis coordinate.
    public let y: Int
    /// Z-axis coordinate.
    public let z: Int

    /// The origin coordinate `(0, 0, 0)`.
    public static let zero = VoxelCoord(x: 0, y: 0, z: 0)

    /// Creates a coordinate at the given integer position.
    public init(x: Int, y: Int, z: Int) {
        self.x = x
        self.y = y
        self.z = z
    }

    /// The six face-adjacent neighbours in orthogonal directions (±x, ±y, ±z).
    public var faceNeighbors: [VoxelCoord] {
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
