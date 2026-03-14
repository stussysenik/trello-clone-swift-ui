import UniformTypeIdentifiers
import CoreTransferable

// MARK: - Custom UTType for List Drag-and-Drop
// Declared in Info.plist as an exported type so the system recognizes it.
// Separate from UTType.trelloCard so SwiftUI can dispatch to the correct
// drop handler — cards drop into lists, lists reorder among themselves.

extension UTType {
    /// Custom uniform type identifier for transferring lists within a board.
    static let trelloList = UTType(exportedAs: "com.trelloclone.list")
}

// MARK: - ListTransferPayload
// Lightweight payload serialized during list drag operations.
// Contains only the IDs needed to locate and reorder the list.

struct ListTransferPayload: Codable, Transferable {
    /// The ID of the list being dragged
    let listID: UUID
    /// The ID of the board the list belongs to (within-board reorder only)
    let sourceBoardID: UUID

    /// Transferable conformance — encodes/decodes as JSON via CodableRepresentation
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .trelloList)
    }
}
