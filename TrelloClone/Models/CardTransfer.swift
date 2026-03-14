import UniformTypeIdentifiers
import CoreTransferable

// MARK: - Custom UTType for Card Drag-and-Drop
// Declared in Info.plist as an exported type so the system recognizes it.

extension UTType {
    /// Custom uniform type identifier for transferring cards between lists.
    static let trelloCard = UTType(exportedAs: "com.trelloclone.card")
}

// MARK: - CardTransferPayload
// Lightweight payload serialized during drag operations.
// Contains only the IDs needed to locate and move the card.

struct CardTransferPayload: Codable, Transferable {
    /// The ID of the card being dragged
    let cardID: UUID
    /// The ID of the list the card originated from
    let sourceListID: UUID

    /// Transferable conformance — encodes/decodes as JSON via CodableRepresentation
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .trelloCard)
    }
}
