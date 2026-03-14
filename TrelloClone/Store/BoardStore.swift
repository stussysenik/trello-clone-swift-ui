import SwiftUI

// MARK: - BoardStore
// Central state manager using the @Observable macro (iOS 17+).
// Owns all boards and provides CRUD + drag-drop + UserDefaults persistence.

@Observable
final class BoardStore {

    // MARK: State

    var boards: [Board]
    var selectedBoardID: UUID?

    // MARK: Persistence Key

    private static let storageKey = "trelloclone.boards"

    // MARK: Init — Load or Seed

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([Board].self, from: data) {
            self.boards = decoded
        } else {
            self.boards = Self.sampleData()
        }
    }

    // MARK: - Board CRUD

    func addBoard(title: String, iconName: String = "rectangle.on.rectangle") {
        let board = Board(title: title, iconName: iconName)
        boards.append(board)
        save()
    }

    func deleteBoard(id: UUID) {
        boards.removeAll { $0.id == id }
        if selectedBoardID == id { selectedBoardID = nil }
        save()
    }

    func updateBoard(_ boardID: UUID, title: String, iconName: String) {
        guard let bi = boards.firstIndex(where: { $0.id == boardID }) else { return }
        boards[bi].title = title
        boards[bi].iconName = iconName
        save()
    }

    // MARK: - List CRUD

    func addList(title: String, to boardID: UUID) {
        guard let bi = boards.firstIndex(where: { $0.id == boardID }) else { return }
        boards[bi].lists.append(BoardList(title: title))
        save()
    }

    func deleteList(id: UUID, from boardID: UUID) {
        guard let bi = boards.firstIndex(where: { $0.id == boardID }) else { return }
        boards[bi].lists.removeAll { $0.id == id }
        save()
    }

    func updateList(_ listID: UUID, title: String, in boardID: UUID) {
        guard let bi = boards.firstIndex(where: { $0.id == boardID }),
              let li = boards[bi].lists.firstIndex(where: { $0.id == listID }) else { return }
        boards[bi].lists[li].title = title
        save()
    }

    // MARK: - Card CRUD

    func addCard(title: String, description: String = "", colorTag: String? = nil,
                 tags: [String] = [], to listID: UUID, in boardID: UUID) {
        guard let bi = boards.firstIndex(where: { $0.id == boardID }),
              let li = boards[bi].lists.firstIndex(where: { $0.id == listID }) else { return }
        let card = Card(title: title, description: description, colorTag: colorTag, tags: tags)
        boards[bi].lists[li].cards.append(card)
        save()
    }

    func deleteCard(id: UUID, from listID: UUID, in boardID: UUID) {
        guard let bi = boards.firstIndex(where: { $0.id == boardID }),
              let li = boards[bi].lists.firstIndex(where: { $0.id == listID }) else { return }
        boards[bi].lists[li].cards.removeAll { $0.id == id }
        save()
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
    }

    /// Search all boards/lists to find a card by ID — used by CardDetailSheet
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

    // MARK: - Drag & Drop

    /// Atomically moves a card from its source list to a destination list at a given index.
    /// Wraps the mutation in a spring animation for smooth visual feedback.
    func moveCard(payload: CardTransferPayload, toListID: UUID, at index: Int, in boardID: UUID) {
        guard let bi = boards.firstIndex(where: { $0.id == boardID }),
              let srcIdx = boards[bi].lists.firstIndex(where: { $0.id == payload.sourceListID }),
              let dstIdx = boards[bi].lists.firstIndex(where: { $0.id == toListID }),
              let cardIdx = boards[bi].lists[srcIdx].cards.firstIndex(where: { $0.id == payload.cardID })
        else { return }

        // Remove from source
        let card = boards[bi].lists[srcIdx].cards.remove(at: cardIdx)

        // Insert at destination — clamp index to valid range
        let clampedIndex = min(index, boards[bi].lists[dstIdx].cards.count)
        boards[bi].lists[dstIdx].cards.insert(card, at: clampedIndex)

        save()
    }

    // MARK: - Cross-Board Move

    /// Moves a card from one board/list to another board/list.
    /// Removes the card from the source and appends it to the destination list.
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
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(boards) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
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
