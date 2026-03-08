import SwiftUI

/// A view that represents a single key on the KelvinGrid on-screen keyboard.
///
/// Conform to this protocol to supply a custom key to `KelvinGridView`
/// via the `.input(cell:)` modifier.
///
/// - `label` — The text displayed on the key: a single letter or `"⌫"` (delete).
/// - `onTap` — Call this when the key is tapped.
public protocol KelvinKeyProtocol: View {
    init(label: String, onTap: @escaping () -> Void)
}
