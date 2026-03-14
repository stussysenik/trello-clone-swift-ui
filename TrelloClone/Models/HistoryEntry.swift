import Foundation

// MARK: - HistoryEntry
// Timestamped audit record for every mutation in the app.
// Stored separately from board data (own UserDefaults key) to avoid bloat.
// Capped at 500 entries — oldest trimmed automatically.

struct HistoryEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let timestamp: Date
    let action: Action
    let entityType: EntityType
    let entityID: UUID
    let description: String
    /// Board context — enables filtering history by board
    let boardID: UUID?

    init(
        id: UUID = UUID(),
        timestamp: Date = .now,
        action: Action,
        entityType: EntityType,
        entityID: UUID,
        description: String,
        boardID: UUID? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.action = action
        self.entityType = entityType
        self.entityID = entityID
        self.description = description
        self.boardID = boardID
    }

    // MARK: - Action

    enum Action: String, Codable, Hashable {
        case created
        case updated
        case deleted
        case moved
    }

    // MARK: - EntityType

    enum EntityType: String, Codable, Hashable {
        case board
        case list
        case card
        case attachment
    }
}
