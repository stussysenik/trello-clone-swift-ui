import SwiftUI

// MARK: - TagPillView
// Capsule pill displaying a tag name with an OKLCH-generated background color.
// Accepts an explicit Color so the parent can use `tagColors(for:)` to
// guarantee adjacent tags never share similar hues.

struct TagPillView: View {
    let tag: String
    var color: Color = AppTheme.tagColor(for: "")

    var body: some View {
        Text(tag)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color)
            .clipShape(Capsule())
    }
}

// MARK: - CardView
// Displays a single card with full interaction layer:
// - Tap navigates to full-viewport CardDetailView via NavigationLink
// - Context menu with Edit / Delete / Move to Board
// - Draggable for card reordering between lists
// Respects Reduce Motion for all decorative animations.

struct CardView: View {
    let card: Card
    let listID: UUID
    let boardID: UUID

    @Environment(BoardStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showDeleteConfirmation = false
    @State private var showMoveSheet = false

    var body: some View {
        NavigationLink(value: CardRoute(cardID: card.id, listID: listID, boardID: boardID)) {
            cardContent
        }
        .buttonStyle(.plain)
        // Drag-and-drop support
        .draggable(CardTransferPayload(cardID: card.id, sourceListID: listID)) {
            CardDragPreview(title: card.title)
        }
        // Context menu (right-click on macOS, long-press on iOS)
        .contextMenu {
            NavigationLink(value: CardRoute(cardID: card.id, listID: listID, boardID: boardID)) {
                Label("Edit Card", systemImage: "pencil")
            }
            Button {
                showMoveSheet = true
            } label: {
                Label("Move to Board...", systemImage: "arrow.right.square")
            }
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete Card", systemImage: "trash")
            }
        }
        // Delete confirmation dialog
        .confirmationDialog(
            "Delete \"\(card.title)\"?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                withAnimation(reduceMotion ? nil : AppTheme.professionalSpring) {
                    store.deleteCard(id: card.id, from: listID, in: boardID)
                }
            }
        } message: {
            Text("This action cannot be undone.")
        }
        // Move to board sheet
        .sheet(isPresented: $showMoveSheet) {
            MoveCardSheet(
                cardID: card.id,
                currentListID: listID,
                currentBoardID: boardID
            )
        }
    }

    // MARK: - Card Content

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
            // Optional color tag strip
            if let hex = card.colorTag {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: UInt(hex.dropFirst(), radix: 16) ?? 0x4285F4))
                    .frame(height: 4)
            }

            Text(card.title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(2)

            // Tag pills — OKLCH colors with adjacent uniqueness
            if !card.tags.isEmpty {
                let colors = AppTheme.tagColors(for: card.tags)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(Array(card.tags.enumerated()), id: \.element) { i, tag in
                            TagPillView(tag: tag, color: colors[i])
                        }
                    }
                }
            }

            if !card.description.isEmpty {
                Text(card.description)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
            }

            // Bottom row: due date + attachment count
            HStack(spacing: AppTheme.spacingSM) {
                if let dueDate = card.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(dueDate, style: .date)
                            .font(.caption2)
                    }
                    .foregroundStyle(dueDate < .now ? .red : AppTheme.textSecondary)
                }

                if !card.attachments.isEmpty {
                    HStack(spacing: 2) {
                        Image(systemName: "paperclip")
                            .font(.caption2)
                        Text("\(card.attachments.count)")
                            .font(.caption2)
                    }
                    .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .padding(.top, card.dueDate != nil || !card.attachments.isEmpty ? 2 : 0)
        }
        .padding(AppTheme.spacingMD)
        .frame(maxWidth: .infinity, minHeight: AppTheme.minTouchTarget, alignment: .leading)
        .background(AppTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSM))
        .appShadow(.card)
    }
}

// MARK: - CardDragPreview
// Lightweight drag ghost — slightly translucent with elevated shadow.

struct CardDragPreview: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(AppTheme.textPrimary)
            .padding(AppTheme.spacingMD)
            .frame(width: AppTheme.listWidth - 32, alignment: .leading)
            .background(AppTheme.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSM))
            .appShadow(.floating)
            .opacity(0.9)
    }
}
