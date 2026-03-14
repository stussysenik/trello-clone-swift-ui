import SwiftUI

// MARK: - TagPillView
// Capsule pill displaying a tag name with a deterministic background color.
// Uses AppTheme.tagColor(for:) for consistent coloring across launches.

struct TagPillView: View {
    let tag: String

    var body: some View {
        Text(tag)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(AppTheme.tagColor(for: tag))
            .clipShape(Capsule())
    }
}

// MARK: - CardView
// Displays a single card with full interaction layer:
// - Press feedback (scale 0.97) for tactile response
// - Tap opens CardDetailSheet for editing
// - Context menu with Edit / Delete / Move to Board
// - Draggable for card reordering between lists
// Respects Reduce Motion for all decorative animations.

struct CardView: View {
    let card: Card
    let listID: UUID
    let boardID: UUID

    @Environment(BoardStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showDetail = false
    @State private var showDeleteConfirmation = false
    @State private var showMoveSheet = false
    @GestureState private var isPressed = false

    var body: some View {
        cardContent
            .contentShape(Rectangle())
            .onTapGesture { showDetail = true }
            // Press feedback via zero-distance drag gesture
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in
                        state = true
                    }
            )
            .scaleEffect(isPressed ? AppTheme.pressScale : 1.0)
            .animation(reduceMotion ? nil : AppTheme.pressAnimation, value: isPressed)
            // Drag-and-drop support
            .draggable(CardTransferPayload(cardID: card.id, sourceListID: listID)) {
                CardDragPreview(title: card.title)
            }
            // Context menu (right-click on macOS, long-press on iOS)
            .contextMenu {
                Button {
                    showDetail = true
                } label: {
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
            // Card detail sheet
            .sheet(isPresented: $showDetail) {
                CardDetailSheet(cardID: card.id, listID: listID, boardID: boardID)
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

            // Tag pills — horizontal scroll for overflow
            if !card.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(card.tags, id: \.self) { tag in
                            TagPillView(tag: tag)
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

            // Due date badge
            if let dueDate = card.dueDate {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text(dueDate, style: .date)
                        .font(.caption2)
                }
                .foregroundStyle(dueDate < .now ? .red : AppTheme.textSecondary)
                .padding(.top, 2)
            }
        }
        .padding(AppTheme.spacingMD)
        .frame(maxWidth: .infinity, minHeight: AppTheme.minTouchTarget, alignment: .leading)
        .background(AppTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSM))
        .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
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
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            .opacity(0.9)
    }
}
