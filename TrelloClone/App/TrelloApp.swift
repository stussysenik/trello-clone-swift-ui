import SwiftUI

// MARK: - TrelloApp
// Entry point for the Trello Clone app.
// Creates services at the root and injects them into the environment
// so all child views can access them via @Environment.

@main
struct TrelloApp: App {
    @State private var store = BoardStore()
    @State private var imageStorage = ImageStorageService()
    @State private var historyStore = HistoryStore()
    @State private var intelligence = CardIntelligenceService()

    var body: some Scene {
        WindowGroup {
            BoardSwitcherView()
                .environment(store)
                .environment(imageStorage)
                .environment(historyStore)
                .environment(intelligence)
                .onAppear {
                    // Wire history store into board store for mutation recording
                    store.historyStore = historyStore
                }
        }
        #if os(macOS)
        .defaultSize(width: 1100, height: 750)
        #endif
    }
}
