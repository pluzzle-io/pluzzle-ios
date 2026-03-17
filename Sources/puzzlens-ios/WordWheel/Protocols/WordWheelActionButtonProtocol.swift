import SwiftUI

/// A view that represents an action button below the word wheel (Submit, Delete, or Clear).
///
/// Conform to this protocol to supply custom action buttons to ``WordWheelView``
/// via the `.actionButton(cell:)` modifier. The view is instantiated once per button type;
/// the `label` parameter distinguishes which action the button triggers.
///
/// ```swift
/// struct MyButton: WordWheelActionButtonProtocol {
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
/// WordWheelView(model: model)
///     .actionButton(cell: MyButton.self)
/// ```
public protocol WordWheelActionButtonProtocol: View {
    /// Creates an action button for the given label and tap handler.
    ///
    /// - Parameters:
    ///   - label: The button's display text — one of `"Submit"`, `"Delete"`, or `"Clear"`.
    ///   - onTap: Call this closure when the button is tapped.
    init(label: String, onTap: @escaping () -> Void)
}
