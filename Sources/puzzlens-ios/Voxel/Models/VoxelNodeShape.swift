import Foundation

/// The 3D shape used to render each cube in a Voxel game.
public enum VoxelNodeShape {
    /// A rounded box. `chamfer` is the absolute corner radius (default `0.1`).
    case box(chamfer: CGFloat = 0.1)
    /// A perfect sphere.
    case sphere
    /// A capsule (cylinder with hemispherical end caps).
    case capsule
}
