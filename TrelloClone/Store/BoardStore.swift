import SwiftUI

// MARK: - BoardStore
// Central state manager using the @Observable macro (iOS 17+).
// Owns all boards and provides CRUD + drag-drop persistence.
// Records all mutations to HistoryStore when available.
//
// Persistence: NSUbiquitousKeyValueStore (iCloud KVS) with UserDefaults
// as local fallback. On init, migrates existing UserDefaults data to iCloud.
// Listens for `didChangeExternallyNotification` to reload when another
// device pushes changes — enabling seamless Mac ↔ iPhone sync.

@Observable
final class BoardStore {

    // MARK: State

    var boards: [Board]
    var selectedBoardID: UUID?

    /// Optional history store — wired in TrelloApp. Records all mutations.
    var historyStore: HistoryStore?

    // MARK: Persistence

    private static let storageKey = "trelloclone.boards"
    private let iCloudStore = NSUbiquitousKeyValueStore.default

    // MARK: Init — iCloud → UserDefaults migration → Sample data

    init() {
        // Priority: iCloud → UserDefaults (one-time migration) → sample data
        if let data = iCloudStore.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([Board].self, from: data) {
            self.boards = decoded
        } else if let data = UserDefaults.standard.data(forKey: Self.storageKey),
                  let decoded = try? JSONDecoder().decode([Board].self, from: data) {
            self.boards = decoded
            // Migrate existing local data up to iCloud
            iCloudStore.set(data, forKey: Self.storageKey)
            iCloudStore.synchronize()
        } else {
            self.boards = Self.sampleData()
        }

        // Listen for changes pushed from other devices
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: iCloudStore,
            queue: .main
        ) { [weak self] _ in
            self?.reloadFromICloud()
        }
        iCloudStore.synchronize()
    }

    /// Reloads board data when another device pushes iCloud changes.
    private func reloadFromICloud() {
        guard let data = iCloudStore.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode([Board].self, from: data) else { return }
        self.boards = decoded
    }

    // MARK: - Board CRUD

    func addBoard(title: String, iconName: String = "rectangle.on.rectangle") {
        let board = Board(title: title, iconName: iconName)
        boards.append(board)
        save()
        historyStore?.record(action: .created, entityType: .board, entityID: board.id,
                             description: "Created board \"\(title)\"", boardID: board.id)
    }

    func deleteBoard(id: UUID) {
        let title = boards.first(where: { $0.id == id })?.title ?? "Unknown"
        boards.removeAll { $0.id == id }
        if selectedBoardID == id { selectedBoardID = nil }
        save()
        historyStore?.record(action: .deleted, entityType: .board, entityID: id,
                             description: "Deleted board \"\(title)\"", boardID: id)
    }

    func updateBoard(_ boardID: UUID, title: String, iconName: String) {
        guard let bi = boards.firstIndex(where: { $0.id == boardID }) else { return }
        boards[bi].title = title
        boards[bi].iconName = iconName
        save()
        historyStore?.record(action: .updated, entityType: .board, entityID: boardID,
                             description: "Updated board \"\(title)\"", boardID: boardID)
    }

    // MARK: - List CRUD

    func addList(title: String, to boardID: UUID) {
        guard let bi = boards.firstIndex(where: { $0.id == boardID }) else { return }
        let list = BoardList(title: title)
        boards[bi].lists.append(list)
        save()
        historyStore?.record(action: .created, entityType: .list, entityID: list.id,
                             description: "Created list \"\(title)\"", boardID: boardID)
    }

    func deleteList(id: UUID, from boardID: UUID) {
        guard let bi = boards.firstIndex(where: { $0.id == boardID }) else { return }
        let title = boards[bi].lists.first(where: { $0.id == id })?.title ?? "Unknown"
        boards[bi].lists.removeAll { $0.id == id }
        save()
        historyStore?.record(action: .deleted, entityType: .list, entityID: id,
                             description: "Deleted list \"\(title)\"", boardID: boardID)
    }

    func updateList(_ listID: UUID, title: String, in boardID: UUID) {
        guard let bi = boards.firstIndex(where: { $0.id == boardID }),
              let li = boards[bi].lists.firstIndex(where: { $0.id == listID }) else { return }
        boards[bi].lists[li].title = title
        save()
        historyStore?.record(action: .updated, entityType: .list, entityID: listID,
                             description: "Renamed list to \"\(title)\"", boardID: boardID)
    }

    // MARK: - Card CRUD

    func addCard(title: String, description: String = "", colorTag: String? = nil,
                 tags: [String] = [], to listID: UUID, in boardID: UUID) {
        guard let bi = boards.firstIndex(where: { $0.id == boardID }),
              let li = boards[bi].lists.firstIndex(where: { $0.id == listID }) else { return }
        let card = Card(title: title, description: description, colorTag: colorTag, tags: tags)
        boards[bi].lists[li].cards.append(card)
        save()
        historyStore?.record(action: .created, entityType: .card, entityID: card.id,
                             description: "Created card \"\(title)\"", boardID: boardID)
    }

    func deleteCard(id: UUID, from listID: UUID, in boardID: UUID) {
        guard let bi = boards.firstIndex(where: { $0.id == boardID }),
              let li = boards[bi].lists.firstIndex(where: { $0.id == listID }) else { return }
        let title = boards[bi].lists[li].cards.first(where: { $0.id == id })?.title ?? "Unknown"
        boards[bi].lists[li].cards.removeAll { $0.id == id }
        save()
        historyStore?.record(action: .deleted, entityType: .card, entityID: id,
                             description: "Deleted card \"\(title)\"", boardID: boardID)
    }

    func updateCard(_ cardID: UUID, title: String, description: String,
                    colorTag: String?, dueDate: Date?, tags: [String] = [],
                    in listID: UUID, boardID: UUID) {
        guard let bi = boards.firstIndex(where: { $0.id == boardID }),
              let li = boards[bi].lists.firstIndex(where: { $0.id == listID }),
              let ci = boards[bi].lists[li].cards.firstIndex(where: { $0.id == cardID })
        else { return }
        boards[bi].lists[li].cards[ci].title = title
        boards[bi].lists[li].cards[ci].description = description
        boards[bi].lists[li].cards[ci].colorTag = colorTag
        boards[bi].lists[li].cards[ci].dueDate = dueDate
        boards[bi].lists[li].cards[ci].tags = tags
        save()
        historyStore?.record(action: .updated, entityType: .card, entityID: cardID,
                             description: "Updated card \"\(title)\"", boardID: boardID)
    }

    /// Search all boards/lists to find a card by ID — used by CardDetailView
    func findCard(id: UUID) -> (boardID: UUID, listID: UUID, card: Card)? {
        for board in boards {
            for list in board.lists {
                if let card = list.cards.first(where: { $0.id == id }) {
                    return (board.id, list.id, card)
                }
            }
        }
        return nil
    }

    // MARK: - Attachment CRUD

    /// Adds an attachment record to a card. Image file is managed by ImageStorageService.
    func addAttachment(filename: String, to cardID: UUID, in listID: UUID, boardID: UUID) {
        guard let bi = boards.firstIndex(where: { $0.id == boardID }),
              let li = boards[bi].lists.firstIndex(where: { $0.id == listID }),
              let ci = boards[bi].lists[li].cards.firstIndex(where: { $0.id == cardID })
        else { return }
        let attachment = Attachment(filename: filename)
        boards[bi].lists[li].cards[ci].attachments.append(attachment)
        save()
        let cardTitle = boards[bi].lists[li].cards[ci].title
        historyStore?.record(action: .created, entityType: .attachment, entityID: attachment.id,
                             description: "Added attachment to \"\(cardTitle)\"", boardID: boardID)
    }

    /// Removes an attachment record from a card.
    func removeAttachment(id: UUID, from cardID: UUID, in listID: UUID, boardID: UUID) {
        guard let bi = boards.firstIndex(where: { $0.id == boardID }),
              let li = boards[bi].lists.firstIndex(where: { $0.id == listID }),
              let ci = boards[bi].lists[li].cards.firstIndex(where: { $0.id == cardID })
        else { return }
        let cardTitle = boards[bi].lists[li].cards[ci].title
        boards[bi].lists[li].cards[ci].attachments.removeAll { $0.id == id }
        save()
        historyStore?.record(action: .deleted, entityType: .attachment, entityID: id,
                             description: "Removed attachment from \"\(cardTitle)\"", boardID: boardID)
    }

    // MARK: - Drag & Drop

    /// Atomically moves a card from its source list to a destination list at a given index.
    /// Wraps the mutation in a spring animation for smooth visual feedback.
    func moveCard(payload: CardTransferPayload, toListID: UUID, at index: Int, in boardID: UUID) {
        guard let bi = boards.firstIndex(where: { $0.id == boardID }),
              let srcIdx = boards[bi].lists.firstIndex(where: { $0.id == payload.sourceListID }),
              let dstIdx = boards[bi].lists.firstIndex(where: { $0.id == toListID }),
              let cardIdx = boards[bi].lists[srcIdx].cards.firstIndex(where: { $0.id == payload.cardID })
        else { return }

        let card = boards[bi].lists[srcIdx].cards.remove(at: cardIdx)
        let clampedIndex = min(index, boards[bi].lists[dstIdx].cards.count)
        boards[bi].lists[dstIdx].cards.insert(card, at: clampedIndex)
        save()

        let destListTitle = boards[bi].lists[dstIdx].title
        historyStore?.record(action: .moved, entityType: .card, entityID: card.id,
                             description: "Moved \"\(card.title)\" to \(destListTitle)", boardID: boardID)
    }

    /// Reorders a list within the same board — removes from current position,
    /// inserts at clamped destination index.
    func moveList(listID: UUID, to index: Int, in boardID: UUID) {
        guard let bi = boards.firstIndex(where: { $0.id == boardID }),
              let srcIdx = boards[bi].lists.firstIndex(where: { $0.id == listID })
        else { return }

        let list = boards[bi].lists.remove(at: srcIdx)
        let clampedIndex = min(index, boards[bi].lists.count)
        boards[bi].lists.insert(list, at: clampedIndex)
        save()
        historyStore?.record(action: .moved, entityType: .list, entityID: listID,
                             description: "Reordered list \"\(list.title)\"", boardID: boardID)
    }

    // MARK: - Cross-Board Move

    /// Moves a card from one board/list to another board/list.
    func moveCardToBoard(cardID: UUID, fromListID: UUID, fromBoardID: UUID,
                         toListID: UUID, toBoardID: UUID) {
        guard let srcBI = boards.firstIndex(where: { $0.id == fromBoardID }),
              let srcLI = boards[srcBI].lists.firstIndex(where: { $0.id == fromListID }),
              let cardIdx = boards[srcBI].lists[srcLI].cards.firstIndex(where: { $0.id == cardID }),
              let dstBI = boards.firstIndex(where: { $0.id == toBoardID }),
              let dstLI = boards[dstBI].lists.firstIndex(where: { $0.id == toListID })
        else { return }

        let card = boards[srcBI].lists[srcLI].cards.remove(at: cardIdx)
        boards[dstBI].lists[dstLI].cards.append(card)
        save()

        let destBoard = boards[dstBI].title
        historyStore?.record(action: .moved, entityType: .card, entityID: cardID,
                             description: "Moved \"\(card.title)\" to board \"\(destBoard)\"", boardID: toBoardID)
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(boards) else { return }
        iCloudStore.set(data, forKey: Self.storageKey)
        iCloudStore.synchronize()
        UserDefaults.standard.set(data, forKey: Self.storageKey) // Local fallback
    }

    // MARK: - Sample Data

    static func sampleData() -> [Board] {
        [
            Board(
                title: "Product Launch",
                lists: [
                    BoardList(title: "Backlog", cards: [
                        Card(title: "Define MVP features", description: "List core features for v1", colorTag: "#4285F4", tags: ["MVP", "Planning"]),
                        Card(title: "Competitor analysis", description: "Review top 5 competitors", tags: ["Research"]),
                        Card(title: "Set up analytics", description: "Integrate event tracking SDK", colorTag: "#0D47A1", tags: ["Backend", "Tracking"]),
                    ]),
                    BoardList(title: "In Progress", cards: [
                        Card(title: "Design landing page", description: "Hero section + feature grid", colorTag: "#1A73E8", tags: ["Design", "Frontend"]),
                        Card(title: "Build onboarding flow", description: "3-step welcome wizard", tags: ["UX"]),
                    ]),
                    BoardList(title: "Review", cards: [
                        Card(title: "API documentation", description: "OpenAPI spec for public endpoints", colorTag: "#4285F4", tags: ["Docs", "API"]),
                    ]),
                    BoardList(title: "Done", cards: [
                        Card(title: "Project setup", description: "Repo, CI/CD, environments", tags: ["DevOps"]),
                        Card(title: "Brand guidelines", description: "Colors, typography, logo usage", colorTag: "#0D47A1", tags: ["Design"]),
                    ]),
                ],
                iconName: "rocket.fill"
            ),
            Board(
                title: "Personal",
                lists: [
                    BoardList(title: "To Do", cards: [
                        Card(title: "Grocery shopping", description: "Milk, eggs, bread, coffee", tags: ["Errands"]),
                        Card(title: "Book dentist appointment", colorTag: "#1A73E8", tags: ["Health", "Urgent"]),
                        Card(title: "Read SwiftUI docs", description: "Focus on Transferable protocol", tags: ["Learning"]),
                    ]),
                    BoardList(title: "In Progress", cards: [
                        Card(title: "Learn Observable macro", description: "Build a sample app", colorTag: "#4285F4", tags: ["Learning", "Swift"]),
                    ]),
                    BoardList(title: "Done", cards: [
                        Card(title: "Set up home office", description: "Desk, monitor, keyboard"),
                        Card(title: "File taxes", colorTag: "#0D47A1", tags: ["Finance"]),
                    ]),
                ],
                iconName: "person.fill"
            ),
        ]
    }
}
