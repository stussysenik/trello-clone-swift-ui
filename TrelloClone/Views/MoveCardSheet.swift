import SwiftUI

// MARK: - MoveCardSheet
// Two-step picker for moving a card to a different board and list.
// Step 1: Select destination board (current board is marked).
// Step 2: Select destination list (current location is disabled).
// Uses presentationDetents for adaptive sizing on iOS.

struct MoveCardSheet: View {
    let cardID: UUID
    let currentListID: UUID
    let currentBoardID: UUID
    /// Optional callback fired after a successful move — use to dismiss parent sheets
    var onMoved: (() -> Void)?

    @Environment(BoardStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var selectedBoardID: UUID?
    @State private var selectedListID: UUID?

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Board Picker
                Section("Destination Board") {
                    ForEach(store.boards) { board in
                        Button {
                            selectedBoardID = board.id
                            selectedListID = nil
                        } label: {
                            HStack {
                                Image(systemName: board.iconName)
                                    .foregroundStyle(AppTheme.primary)
                                    .frame(width: 24)
                                Text(board.title)
                                    .foregroundStyle(AppTheme.textPrimary)
                                Spacer()
                                if board.id == currentBoardID {
                                    Text("Current")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                if selectedBoardID == board.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(AppTheme.accent)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                // MARK: List Picker
                if let boardID = selectedBoardID,
                   let board = store.boards.first(where: { $0.id == boardID }) {
                    Section("Destination List") {
                        ForEach(board.lists) { list in
                            let isCurrent = boardID == currentBoardID && list.id == currentListID
                            Button {
                                if !isCurrent {
                                    selectedListID = list.id
                                }
                            } label: {
                                HStack {
                                    Text(list.title)
                                        .foregroundStyle(isCurrent ? AppTheme.textSecondary : AppTheme.textPrimary)
                                    Spacer()
                                    if isCurrent {
                                        Text("Current")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.textSecondary)
                                    }
                                    if selectedListID == list.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(AppTheme.accent)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(isCurrent)
                        }
                    }
                }
            }
            .navigationTitle("Move Card")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Move") {
                        guard let toBoardID = selectedBoardID,
                              let toListID = selectedListID else { return }
                        store.moveCardToBoard(
                            cardID: cardID,
                            fromListID: currentListID,
                            fromBoardID: currentBoardID,
                            toListID: toListID,
                            toBoardID: toBoardID
                        )
                        dismiss()
                        onMoved?()
                    }
                    .disabled(selectedListID == nil)
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}
