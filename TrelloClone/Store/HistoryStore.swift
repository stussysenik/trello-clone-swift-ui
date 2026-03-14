import Foundation

// MARK: - HistoryStore
// Separate @Observable store for version history, persisted in its own
// UserDefaults key ("trelloclone.history") to avoid bloating board data.
// Capped at 500 entries — oldest are trimmed on each record() call.

@Observable
final class HistoryStore {

    // MARK: State

    var entries: [HistoryEntry]

    // MARK: Constants

    private static let storageKey = "trelloclone.history"
    private static let maxEntries = 500

    // MARK: Init

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: data) {
            self.entries = decoded
        } else {
            self.entries = []
        }
    }

    // MARK: - Record

    /// Records a new history entry. Trims oldest entries if cap exceeded.
    func record(
        action: HistoryEntry.Action,
        entityType: HistoryEntry.EntityType,
        entityID: UUID,
        description: String,
        boardID: UUID? = nil
    ) {
        let entry = HistoryEntry(
            action: action,
            entityType: entityType,
            entityID: entityID,
            description: description,
            boardID: boardID
        )
        entries.insert(entry, at: 0)

        // Trim to cap
        if entries.count > Self.maxEntries {
            entries = Array(entries.prefix(Self.maxEntries))
        }

        save()
    }

    // MARK: - Queries

    /// Returns history entries for a specific entity (card, list, board, attachment).
    func history(for entityID: UUID) -> [HistoryEntry] {
        entries.filter { $0.entityID == entityID }
    }

    /// Returns history entries associated with a specific board.
    func history(forBoard boardID: UUID) -> [HistoryEntry] {
        entries.filter { $0.boardID == boardID }
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }
}
