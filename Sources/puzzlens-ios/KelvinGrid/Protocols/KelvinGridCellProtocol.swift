import SwiftUI

/// A view that represents a single cell in the KelvinGrid.
///
/// Conform to this protocol to supply a custom cell to `KelvinGridView`
/// via the `.grid(spacing:cell:)` modifier.
///
/// - `letter`      — The letter displayed in the cell, or an empty string if the cell is empty.
/// - `state`       — The evaluation state that determines the cell's colour.
/// - `isActiveRow` — `true` when this cell belongs to the row currently being typed.
///                   Use this to render a highlighted border indicating the active row.
public protocol KelvinGridCellProtocol: View {
    init(letter: String, state: KelvinCellState, isActiveRow: Bool)
}
