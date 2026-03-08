import SwiftUI

/// A view that represents an action button below the word wheel (Submit, Delete, Clear).
///
/// Conform to this protocol to supply custom action buttons to `WordWheelView`
/// via the `.actionButton(cell:)` modifier.
///
/// - `label`  — The button's display text (e.g. `"Submit"`, `"Delete"`, `"Clear"`).
/// - `onTap`  — Call this when the button is tapped.
public protocol WordWheelActionButtonProtocol: View {
    init(label: String, onTap: @escaping () -> Void)
}
