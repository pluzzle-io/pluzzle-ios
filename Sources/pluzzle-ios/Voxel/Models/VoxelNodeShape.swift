import Foundation

/// The 3D shape used to render each node in a Voxel game.
///
/// Pass a shape to ``VoxelGameView`` via the `.node(shape:size:)` modifier.
///
/// ```swift
/// VoxelGameView(model: model)
///     .node(shape: .sphere, size: 0.8)
/// ```
public enum VoxelNodeShape {
    /// A rounded box.
    /// - Parameter chamfer: The absolute corner radius applied to each edge. Defaults to `0.1`.
    case box(chamfer: CGFloat = 0.1)
    /// A perfect sphere whose diameter equals the configured node size.
    case sphere
    /// A capsule (cylinder with hemispherical end caps).
    case capsule
}
