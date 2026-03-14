import Foundation

// MARK: - CardRoute
// Navigation route for pushing a full-viewport card detail view.
// SwiftUI's NavigationStack dispatches .navigationDestination by type,
// so CardRoute (for cards) and UUID (for boards) coexist without conflict.

struct CardRoute: Hashable {
    let cardID: UUID
    let listID: UUID
    let boardID: UUID
}
