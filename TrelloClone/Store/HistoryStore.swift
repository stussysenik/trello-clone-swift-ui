import Foundation

// MARK: - HistoryStore
// Separate @Observable store for version history, synced via iCloud KVS.
// Persisted in its own key ("trelloclone.history") to avoid bloating board data.
// Capped at 500 entries — oldest are trimmed on each record() call.
// Uses NSUbiquitousKeyValueStore with UserDefaults as local fallback.

@Observable
final class HistoryStore {

    // MARK: State

    var entries: [HistoryEntry]

    // MARK: Constants

    private static let storageKey = "trelloclone.history"
    private static let maxEntries = 500
    private let iCloudStore = NSUbiquitousKeyValueStore.default

    // MARK: Init

    init() {
        // Priority: iCloud → UserDefaults (migration) → empty
        if let data = iCloudStore.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: data) {
            self.entries = decoded
        } else if let data = UserDefaults.standard.data(forKey: Self.storageKey),
                  let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: data) {
            self.entries = decoded
            iCloudStore.set(data, forKey: Self.storageKey)
            iCloudStore.synchronize()
        } else {
            self.entries = []
        }

        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: iCloudStore,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            if let reason = notification.userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int,
               reason == NSUbiquitousKeyValueStoreQuotaViolationChange {
                print("[HistoryStore] ⚠️ iCloud KVS quota exceeded (1MB limit)")
            }
            self.reloadFromICloud()
        }
        iCloudStore.synchronize()
    }

    private func reloadFromICloud() {
        guard let data = iCloudStore.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: data) else { return }
        self.entries = decoded
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
        iCloudStore.set(data, forKey: Self.storageKey)
        iCloudStore.synchronize()
        UserDefaults.standard.set(data, forKey: Self.storageKey) // Local fallback
    }
}
