import SwiftUI
import PhotosUI

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
    @Environment(ImageStorageService.self) private var imageStorage
    @Environment(HistoryStore.self) private var historyStore
    @Environment(CardIntelligenceService.self) private var intelligence
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

    // Attachment state
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var thumbnailCache: [String: PlatformImage] = [:]

    // AI state — ambient tag suggestions
    @State private var suggestedTags: [String] = []

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

    /// Current card from store (live)
    private var currentCard: Card? {
        store.findCard(id: route.cardID)?.card
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
                    .frame(minHeight: 200)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, AppTheme.spacingMD)

                Divider()
                    .padding(.horizontal, AppTheme.spacingLG)

                // MARK: Attachments
                attachmentsSection

                Divider()
                    .padding(.horizontal, AppTheme.spacingLG)

                // MARK: History
                historySection

                // Placeholder for future layers
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
                // Delete all attachment files before removing card
                if let card = currentCard {
                    for attachment in card.attachments {
                        imageStorage.deleteImage(filename: attachment.filename)
                    }
                }
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
        .onChange(of: selectedPhoto) { _, newItem in
            handlePhotoSelection(newItem)
        }
        .onAppear { loadCard() }
        .onDisappear { saveIfChanged() }
        .onChange(of: description) { _, _ in
            // Debounced: update suggestions when description changes
            updateSuggestions()
        }
        .onChange(of: title) { _, _ in
            updateSuggestions()
        }
    }

    // MARK: - Attachments Section

    // MARK: - History Section

    private var historySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            DisclosureGroup {
                HistoryTimelineView(entries: historyStore.history(for: route.cardID))
                    .padding(.top, AppTheme.spacingXS)
            } label: {
                Text("History")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
            }
        }
        .padding(.horizontal, AppTheme.spacingLG)
        .padding(.top, AppTheme.spacingLG)
        .padding(.bottom, AppTheme.spacingMD)
    }

    private var attachmentsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            HStack {
                Text("Attachments")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("Add", systemImage: "plus")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.accent)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppTheme.spacingLG)
            .padding(.top, AppTheme.spacingLG)

            if let card = currentCard, !card.attachments.isEmpty {
                // Thumbnail grid — 3 columns
                let columns = [GridItem(.adaptive(minimum: 90), spacing: AppTheme.spacingSM)]
                LazyVGrid(columns: columns, spacing: AppTheme.spacingSM) {
                    ForEach(card.attachments) { attachment in
                        attachmentThumbnail(attachment)
                    }
                }
                .padding(.horizontal, AppTheme.spacingLG)
            } else {
                Text("No attachments")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.horizontal, AppTheme.spacingLG)
            }
        }
        .padding(.bottom, AppTheme.spacingMD)
    }

    private func attachmentThumbnail(_ attachment: Attachment) -> some View {
        Group {
            if let thumb = thumbnailCache[attachment.filename] {
                Image(platformImage: thumb)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(AppTheme.listBackground)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .onAppear {
                        loadThumbnail(for: attachment)
                    }
            }
        }
        .frame(height: 90)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSM))
        .contextMenu {
            Button(role: .destructive) {
                withAnimation(reduceMotion ? nil : AppTheme.fastSpring) {
                    imageStorage.deleteImage(filename: attachment.filename)
                    store.removeAttachment(id: attachment.id, from: route.cardID, in: route.listID, boardID: route.boardID)
                    thumbnailCache.removeValue(forKey: attachment.filename)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
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
        let colors = AppTheme.tagColors(for: tags)
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(tags.enumerated()), id: \.element) { i, tag in
                    let tagColor = colors[i]
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
                    .background(tagColor)
                    .clipShape(Capsule())
                }

                // AI ghost suggestions — dimmed pills, tap to accept
                ForEach(suggestedTags.filter { !tags.contains($0) }, id: \.self) { suggestion in
                    let suggestionColor = AppTheme.tagColor(for: suggestion)
                    Button {
                        withAnimation(reduceMotion ? nil : AppTheme.fastSpring) {
                            tags.append(suggestion)
                            suggestedTags.removeAll { $0 == suggestion }
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "plus")
                                .font(.system(size: 8, weight: .bold))
                            Text(suggestion)
                                .font(.caption.weight(.medium))
                        }
                        .foregroundStyle(suggestionColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(suggestionColor.opacity(0.15))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
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

        // Preload thumbnails
        for attachment in card.attachments {
            loadThumbnail(for: attachment)
        }

        // Generate initial AI tag suggestions
        updateSuggestions()
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

    private func handlePhotoSelection(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self) else { return }
            let filename = "\(UUID().uuidString).jpg"
            guard imageStorage.saveImage(data, filename: filename) else { return }
            await MainActor.run {
                withAnimation(reduceMotion ? nil : AppTheme.fastSpring) {
                    store.addAttachment(filename: filename, to: route.cardID, in: route.listID, boardID: route.boardID)
                }
                // Load thumbnail immediately
                if let thumb = imageStorage.loadThumbnail(filename: filename) {
                    thumbnailCache[filename] = thumb
                }
            }
            selectedPhoto = nil
        }
    }

    private func loadThumbnail(for attachment: Attachment) {
        guard thumbnailCache[attachment.filename] == nil else { return }
        if let thumb = imageStorage.loadThumbnail(filename: attachment.filename) {
            thumbnailCache[attachment.filename] = thumb
        }
    }

    /// Regenerates AI tag suggestions from current title + description
    private func updateSuggestions() {
        suggestedTags = intelligence.suggestTags(title: title, description: description)
    }
}

// MARK: - Image Extension for Cross-Platform PlatformImage → SwiftUI Image

extension Image {
    init(platformImage: PlatformImage) {
        #if canImport(UIKit)
        self.init(uiImage: platformImage)
        #elseif canImport(AppKit)
        self.init(nsImage: platformImage)
        #endif
    }
}
