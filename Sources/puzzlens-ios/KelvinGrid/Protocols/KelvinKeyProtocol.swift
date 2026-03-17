import SwiftUI

/// A view that represents a single key on the KelvinGrid on-screen keyboard.
///
/// Conform to this protocol to supply a custom key to ``KelvinGridView``
/// via the `.input(cell:)` modifier.
///
/// ```swift
/// struct MyKey: KelvinKeyProtocol {
///     let label: String
///     let onTap: () -> Void
///
///     init(label: String, onTap: @escaping () -> Void) {
///         self.label = label; self.onTap = onTap
///     }
///
///     var body: some View { … }
/// }
///
/// KelvinGridView(model: model)
///     .input(cell: MyKey.self)
/// ```
public protocol KelvinKeyProtocol: View {
    /// Creates a key view for the given label and tap handler.
    ///
    /// - Parameters:
    ///   - label: The text displayed on the key — a single uppercase letter or `"⌫"` for delete.
    ///   - onTap: Call this closure when the key is tapped.
    init(label: String, onTap: @escaping () -> Void)
}
