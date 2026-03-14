import Foundation

// MARK: - Card
// The smallest unit in the Trello hierarchy. Lives inside a BoardList.
// Value type (struct) so SwiftUI can efficiently diff changes.

struct Card: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var description: String
    /// Optional color tag displayed as a thin strip at the top of the card
    var colorTag: String?
    /// Optional due date shown in the card detail sheet
    var dueDate: Date?
    /// Text-based tags displayed as colored pills on the card
    var tags: [String]
    let createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        colorTag: String? = nil,
        dueDate: Date? = nil,
        tags: [String] = [],
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.colorTag = colorTag
        self.dueDate = dueDate
        self.tags = tags
        self.createdAt = createdAt
    }

    /// Custom decoder for backward compatibility — existing UserDefaults data
    /// may not contain the `tags` field.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        colorTag = try container.decodeIfPresent(String.self, forKey: .colorTag)
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}

// MARK: - BoardList
// A vertical column of cards within a board (e.g. "To Do", "In Progress").

struct BoardList: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var cards: [Card]

    init(
        id: UUID = UUID(),
        title: String,
        cards: [Card] = []
    ) {
        self.id = id
        self.title = title
        self.cards = cards
    }
}

// MARK: - Board
// Top-level container. Each board has an SF Symbol icon and contains lists.

struct Board: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var lists: [BoardList]
    /// SF Symbol name for the board icon shown in the switcher grid
    var iconName: String

    init(
        id: UUID = UUID(),
        title: String,
        lists: [BoardList] = [],
        iconName: String = "rectangle.on.rectangle"
    ) {
        self.id = id
        self.title = title
        self.lists = lists
        self.iconName = iconName
    }

    /// Total number of cards across all lists
    var totalCards: Int {
        lists.reduce(0) { $0 + $1.cards.count }
    }
}

// MARK: - ViewMode
// Controls how the home screen board switcher displays boards.
// Persisted via @AppStorage as a raw String value.

enum ViewMode: String, CaseIterable, Codable {
    case grid
    case list
    case compact

    /// SF Symbol shown in the toolbar segmented picker
    var iconName: String {
        switch self {
        case .grid: return "square.grid.2x2"
        case .list: return "list.bullet"
        case .compact: return "rectangle.grid.1x2"
        }
    }

    /// Human-readable label for accessibility
    var label: String {
        switch self {
        case .grid: return "Grid"
        case .list: return "List"
        case .compact: return "Compact"
        }
    }
}
