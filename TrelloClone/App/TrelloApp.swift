import SwiftUI

// MARK: - TrelloApp
// Entry point for the Trello Clone app.
// Creates the BoardStore at the root and injects it into the environment
// so all child views can access it via @Environment(BoardStore.self).

@main
struct TrelloApp: App {
    @State private var store = BoardStore()

    var body: some Scene {
        WindowGroup {
            BoardSwitcherView()
                .environment(store)
        }
        #if os(macOS)
        .defaultSize(width: 1100, height: 750)
        #endif
    }
}
