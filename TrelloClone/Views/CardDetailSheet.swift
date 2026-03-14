import SwiftUI

// MARK: - CardDetailSheet
// Full card editing sheet with mobile-first layout.
// Supports editing title, description, color tag, tags, due date,
// moving to another board, and deleting.
// Uses presentationDetents for adaptive sizing — starts medium, expandable to large.

struct CardDetailSheet: View {
    let cardID: UUID
    let listID: UUID
    let boardID: UUID

    @Environment(BoardStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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

    /// Available color tag options
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

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Title
                Section("Title") {
                    TextField("Card title", text: $title)
                        .focused($isTitleFocused)
                }

                // MARK: Description
                Section("Description") {
                    TextEditor(text: $description)
                        .frame(minHeight: 60, maxHeight: 160)
                }

                // MARK: Tags
                Section("Tags") {
                    // Existing tags as removable pills
                    if !tags.isEmpty {
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
                            }
                            .padding(.vertical, AppTheme.spacingXS)
                        }
                    }

                    // Add new tag
                    HStack {
                        TextField("Add tag...", text: $newTagText)
                            .onSubmit { addTag() }
                        Button {
                            addTag()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(AppTheme.accent)
                        }
                        .buttonStyle(.plain)
                        .disabled(newTagText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                // MARK: Color Tag
                Section("Color Tag") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppTheme.spacingSM) {
                            // "None" option to clear color tag
                            Button {
                                colorTag = nil
                            } label: {
                                Circle()
                                    .strokeBorder(AppTheme.cardBorder, lineWidth: 2)
                                    .frame(width: 32, height: 32)
                                    .overlay {
                                        if colorTag == nil {
                                            Image(systemName: "checkmark")
                                                .font(.caption.weight(.bold))
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
                                        .frame(width: 32, height: 32)
                                        .overlay {
                                            if colorTag == option.hex {
                                                Image(systemName: "checkmark")
                                                    .font(.caption.weight(.bold))
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, AppTheme.spacingXS)
                    }
                }

                // MARK: Due Date
                Section("Due Date") {
                    Toggle("Set due date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker(
                            "Due date",
                            selection: Binding(
                                get: { dueDate ?? .now },
                                set: { dueDate = $0 }
                            ),
                            displayedComponents: [.date]
                        )
                    }
                }

                // MARK: Move to Board
                Section {
                    Button {
                        showMoveSheet = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("Move to Board...", systemImage: "arrow.right.square")
                            Spacer()
                        }
                    }
                }

                // MARK: Delete
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("Delete Card", systemImage: "trash")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Card")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let finalDueDate = hasDueDate ? dueDate : nil
                        withAnimation(reduceMotion ? nil : AppTheme.professionalSpring) {
                            store.updateCard(
                                cardID,
                                title: title.trimmingCharacters(in: .whitespaces),
                                description: description.trimmingCharacters(in: .whitespaces),
                                colorTag: colorTag,
                                dueDate: finalDueDate,
                                tags: tags,
                                in: listID,
                                boardID: boardID
                            )
                        }
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog(
                "Delete this card?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    withAnimation(reduceMotion ? nil : AppTheme.professionalSpring) {
                        store.deleteCard(id: cardID, from: listID, in: boardID)
                    }
                    dismiss()
                }
            } message: {
                Text("This action cannot be undone.")
            }
            .sheet(isPresented: $showMoveSheet) {
                MoveCardSheet(
                    cardID: cardID,
                    currentListID: listID,
                    currentBoardID: boardID,
                    onMoved: { dismiss() }
                )
            }
            .presentationDetents([.medium, .large])
            .onAppear {
                // Initialize state from current card data
                if let result = store.findCard(id: cardID) {
                    title = result.card.title
                    description = result.card.description
                    colorTag = result.card.colorTag
                    dueDate = result.card.dueDate
                    hasDueDate = result.card.dueDate != nil
                    tags = result.card.tags
                }
                isTitleFocused = true
            }
        }
    }

    // MARK: - Helpers

    private func addTag() {
        let trimmed = newTagText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }
        withAnimation(reduceMotion ? nil : AppTheme.fastSpring) {
            tags.append(trimmed)
        }
        newTagText = ""
    }
}
