import SwiftUI

// MARK: - CardDetailView
// Full-viewport card editor that replaces the old sheet-based CardDetailSheet.
// Pushed via NavigationStack using CardRoute — gives a focused, iA Writer-like
// editing experience with auto-save on disappear (no Save/Cancel buttons).
//
// Layout philosophy: Notion-style property rows + iA Writer serif body.
// Auto-save pattern: captures original state on appear, saves only if changed.

struct CardDetailView: View {
    let route: CardRoute

    @Environment(BoardStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss

    // MARK: Editing State

    @State private var title = ""
    @State private var description = ""
    @State private var colorTag: String?
    @State private var dueDate: Date?
    @State private var hasDueDate = false
    @State private var tags: [String] = []
    @State private var newTagText = ""
    @State private var showDeleteConfirmation = false
    @State private var showMoveSheet = false
    @FocusState private var isTitleFocused: Bool

    // Original snapshot for dirty-checking
    @State private var originalTitle = ""
    @State private var originalDescription = ""
    @State private var originalColorTag: String?
    @State private var originalDueDate: Date?
    @State private var originalTags: [String] = []

    /// Available color tag options — shared palette
    private let colorOptions: [(name: String, hex: String)] = [
        ("Blue", "#4285F4"),
        ("Navy", "#0D47A1"),
        ("Primary", "#1A73E8"),
        ("Red", "#EA4335"),
        ("Green", "#34A853"),
        ("Orange", "#FA7B17"),
        ("Purple", "#A142F4"),
        ("Teal", "#24C1E0"),
    ]

    // MARK: Computed Helpers

    /// Resolve current board from store
    private var board: Board? {
        store.boards.first { $0.id == route.boardID }
    }

    /// Resolve current list from board
    private var list: BoardList? {
        board?.lists.first { $0.id == route.listID }
    }

    /// Check if any field has been modified
    private var hasChanges: Bool {
        title != originalTitle ||
        description != originalDescription ||
        colorTag != originalColorTag ||
        (hasDueDate ? dueDate : nil) != originalDueDate ||
        tags != originalTags
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // MARK: Title — Large inline-editable heading
                TextField("Untitled", text: $title, axis: .vertical)
                    .font(AppTheme.cardDetailTitleFont)
                    .foregroundStyle(AppTheme.textPrimary)
                    .focused($isTitleFocused)
                    .padding(.horizontal, AppTheme.spacingLG)
                    .padding(.top, AppTheme.spacingLG)
                    .padding(.bottom, AppTheme.spacingSM)

                // MARK: Breadcrumb — "Board Name > List Name"
                if let board, let list {
                    HStack(spacing: AppTheme.spacingXS) {
                        Image(systemName: board.iconName)
                            .font(.caption)
                        Text(board.title)
                            .font(.caption.weight(.medium))
                        Text("\u{203A}")
                            .font(.caption)
                        Text(list.title)
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.horizontal, AppTheme.spacingLG)
                    .padding(.bottom, AppTheme.spacingMD)
                }

                Divider()
                    .padding(.horizontal, AppTheme.spacingLG)

                // MARK: Properties (Notion-style key-value rows)
                VStack(spacing: 0) {
                    // Tags
                    propertyRow(icon: "tag", label: "Tags") {
                        tagsContent
                    }

                    // Color
                    propertyRow(icon: "paintpalette", label: "Color") {
                        colorContent
                    }

                    // Due Date
                    propertyRow(icon: "calendar", label: "Due Date") {
                        dueDateContent
                    }

                    // Created
                    if let result = store.findCard(id: route.cardID) {
                        propertyRow(icon: "clock", label: "Created") {
                            Text(result.card.createdAt, style: .relative)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
                .padding(.vertical, AppTheme.spacingSM)

                Divider()
                    .padding(.horizontal, AppTheme.spacingLG)

                // MARK: Description (iA Writer style — serif font, generous line spacing)
                Text("Description")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.horizontal, AppTheme.spacingLG)
                    .padding(.top, AppTheme.spacingLG)
                    .padding(.bottom, AppTheme.spacingSM)

                TextEditor(text: $description)
                    .font(AppTheme.cardDetailBodyFont)
                    .lineSpacing(AppTheme.cardDetailBodyLineSpacing)
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(minHeight: 300)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, AppTheme.spacingMD)

                // Placeholder sections for future layers
                // [Attachments — Layer 3]
                // [History — Layer 4]
                // [AI Insights — Layer 5]

                Spacer(minLength: 100)
            }
        }
        .background(AppTheme.cardSurface)
        .navigationTitle("")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
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
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog(
            "Delete this card?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                withAnimation(reduceMotion ? nil : AppTheme.professionalSpring) {
                    store.deleteCard(id: route.cardID, from: route.listID, in: route.boardID)
                }
                dismiss()
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .sheet(isPresented: $showMoveSheet) {
            MoveCardSheet(
                cardID: route.cardID,
                currentListID: route.listID,
                currentBoardID: route.boardID,
                onMoved: { dismiss() }
            )
        }
        .onAppear { loadCard() }
        .onDisappear { saveIfChanged() }
    }

    // MARK: - Property Row Template

    /// Notion-style property row with icon, label, and inline content.
    private func propertyRow<Content: View>(
        icon: String,
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .center, spacing: AppTheme.spacingMD) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 20)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 70, alignment: .leading)

            content()

            Spacer(minLength: 0)
        }
        .frame(minHeight: AppTheme.minTouchTarget)
        .padding(.horizontal, AppTheme.spacingLG)
    }

    // MARK: - Tags Content

    private var tagsContent: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(tags, id: \.self) { tag in
                    HStack(spacing: 4) {
                        Text(tag)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white)
                        Button {
                            withAnimation(reduceMotion ? nil : AppTheme.fastSpring) {
                                tags.removeAll { $0 == tag }
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppTheme.tagColor(for: tag))
                    .clipShape(Capsule())
                }

                // Inline add tag
                HStack(spacing: 4) {
                    TextField("Add...", text: $newTagText)
                        .font(.caption)
                        .frame(width: 60)
                        .onSubmit { addTag() }
                    Button {
                        addTag()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.caption)
                            .foregroundStyle(AppTheme.accent)
                    }
                    .buttonStyle(.plain)
                    .disabled(newTagText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    // MARK: - Color Content

    private var colorContent: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.spacingSM) {
                // None option
                Button {
                    colorTag = nil
                } label: {
                    Circle()
                        .strokeBorder(AppTheme.cardBorder, lineWidth: 2)
                        .frame(width: 28, height: 28)
                        .overlay {
                            if colorTag == nil {
                                Image(systemName: "checkmark")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                }
                .buttonStyle(.plain)

                ForEach(colorOptions, id: \.hex) { option in
                    Button {
                        colorTag = option.hex
                    } label: {
                        Circle()
                            .fill(Color(hex: UInt(option.hex.dropFirst(), radix: 16) ?? 0x4285F4))
                            .frame(width: 28, height: 28)
                            .overlay {
                                if colorTag == option.hex {
                                    Image(systemName: "checkmark")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.white)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Due Date Content

    private var dueDateContent: some View {
        HStack(spacing: AppTheme.spacingSM) {
            Toggle("", isOn: $hasDueDate)
                .labelsHidden()
                .tint(AppTheme.accent)

            if hasDueDate {
                DatePicker(
                    "",
                    selection: Binding(
                        get: { dueDate ?? .now },
                        set: { dueDate = $0 }
                    ),
                    displayedComponents: [.date]
                )
                .labelsHidden()
            }
        }
    }

    // MARK: - Helpers

    private func loadCard() {
        guard let result = store.findCard(id: route.cardID) else { return }
        let card = result.card
        title = card.title
        description = card.description
        colorTag = card.colorTag
        dueDate = card.dueDate
        hasDueDate = card.dueDate != nil
        tags = card.tags

        // Snapshot originals for dirty-checking
        originalTitle = card.title
        originalDescription = card.description
        originalColorTag = card.colorTag
        originalDueDate = card.dueDate
        originalTags = card.tags
    }

    /// Auto-save on disappear — only persists if changes were made (Linear/Notion pattern)
    private func saveIfChanged() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty, hasChanges else { return }
        let finalDueDate = hasDueDate ? dueDate : nil
        store.updateCard(
            route.cardID,
            title: trimmedTitle,
            description: description.trimmingCharacters(in: .whitespaces),
            colorTag: colorTag,
            dueDate: finalDueDate,
            tags: tags,
            in: route.listID,
            boardID: route.boardID
        )
    }

    private func addTag() {
        let trimmed = newTagText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }
        withAnimation(reduceMotion ? nil : AppTheme.fastSpring) {
            tags.append(trimmed)
        }
        newTagText = ""
    }
}
