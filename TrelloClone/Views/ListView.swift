import SwiftUI

// MARK: - ListView
// A vertical column representing a single BoardList.
// Features:
// - Responsive width (85% on compact, 280pt on regular)
// - Inline card creation (replaces modal AddCardSheet)
// - Materializing card transitions (opacity + offset + blur)
// - Header with rename and overflow menu (delete list)
// - Empty state when no cards exist
// - Drop target for card drag-and-drop with professional spring

struct ListView: View {
    let boardID: UUID
    let list: BoardList
    var listWidth: CGFloat = AppTheme.listWidth

    @Environment(BoardStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isTargeted = false
    @State private var isAddingCard = false
    @State private var newCardTitle = ""
    @State private var showRenameAlert = false
    @State private var renameText = ""
    @State private var showDeleteConfirmation = false
    @FocusState private var isNewCardFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: Header
            header

            // MARK: Card Stack — double-tap empty area to create card inline
            ScrollView {
                LazyVStack(spacing: AppTheme.spacingSM) {
                    if list.cards.isEmpty {
                        // Empty state
                        Text("No cards yet")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.spacingXL)
                    } else {
                        ForEach(Array(list.cards.enumerated()), id: \.element.id) { index, card in
                            CardView(card: card, listID: list.id, boardID: boardID)
                                // Per-card drop destination for within-list reorder
                                .dropDestination(for: CardTransferPayload.self) { payloads, _ in
                                    guard let payload = payloads.first else { return false }
                                    withAnimation(reduceMotion ? nil : AppTheme.bouncyDropSpring) {
                                        store.moveCard(payload: payload, toListID: list.id, at: index, in: boardID)
                                    }
                                    return true
                                }
                                .transition(.asymmetric(
                                    insertion: .opacity
                                        .combined(with: .offset(y: AppTheme.entryOffset))
                                        .combined(with: .scale(scale: 0.98)),
                                    removal: .opacity
                                        .combined(with: .scale(scale: AppTheme.minEntryScale))
                                ))
                        }
                    }
                }
                .padding(.horizontal, AppTheme.spacingMD)
                .padding(.bottom, AppTheme.spacingSM)
            }
            .contentShape(Rectangle()) // Extend tap target to empty areas
            .onTapGesture(count: 2) {
                isAddingCard = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isNewCardFocused = true
                }
            }

            // MARK: Inline Card Creation
            inlineCardCreation
        }
        .frame(width: listWidth)
        .background(AppTheme.listBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMD))
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMD)
                .stroke(isTargeted ? AppTheme.accent : .clear, lineWidth: 2)
                .scaleEffect(isTargeted ? 1.02 : 1.0)
                .animation(isTargeted ? AppTheme.dropZonePulseAnimation : .default, value: isTargeted)
        )
        // MARK: Drop Target
        .dropDestination(for: CardTransferPayload.self) { payloads, _ in
            guard let payload = payloads.first else { return false }
            withAnimation(reduceMotion ? nil : AppTheme.bouncyDropSpring) {
                store.moveCard(
                    payload: payload,
                    toListID: list.id,
                    at: list.cards.count,
                    in: boardID
                )
            }
            return true
        } isTargeted: { targeted in
            withAnimation(reduceMotion ? nil : AppTheme.dropTargetAnimation) {
                isTargeted = targeted
            }
        }
        // Rename alert
        .alert("Rename List", isPresented: $showRenameAlert) {
            TextField("List title", text: $renameText)
            Button("Cancel", role: .cancel) { }
            Button("Rename") {
                let trimmed = renameText.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                withAnimation(reduceMotion ? nil : AppTheme.professionalSpring) {
                    store.updateList(list.id, title: trimmed, in: boardID)
                }
            }
        }
        // Delete confirmation
        .confirmationDialog(
            "Delete \"\(list.title)\"?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                withAnimation(reduceMotion ? nil : AppTheme.professionalSpring) {
                    store.deleteList(id: list.id, from: boardID)
                }
            }
        } message: {
            Text("All cards in this list will be deleted.")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text(list.title)
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)

            Spacer()

            Text("\(list.cards.count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, AppTheme.spacingSM)
                .padding(.vertical, AppTheme.spacingXS)
                .background(AppTheme.cardBorder.opacity(0.5))
                .clipShape(Capsule())

            // Overflow menu
            Menu {
                Button {
                    renameText = list.title
                    showRenameAlert = true
                } label: {
                    Label("Rename", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete List", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.body)
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(width: AppTheme.minTouchTarget, height: AppTheme.minTouchTarget)
                    .contentShape(Rectangle())
            }
        }
        .padding(.leading, AppTheme.spacingMD)
        .padding(.top, AppTheme.spacingMD)
        .padding(.bottom, AppTheme.spacingSM)
    }

    // MARK: - Inline Card Creation

    private var inlineCardCreation: some View {
        Group {
            if isAddingCard {
                VStack(spacing: AppTheme.spacingSM) {
                    TextField("Card title...", text: $newCardTitle)
                        .textFieldStyle(.roundedBorder)
                        .focused($isNewCardFocused)
                        .onSubmit {
                            submitNewCard()
                        }

                    HStack {
                        Button("Add") {
                            submitNewCard()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.primary)
                        .disabled(newCardTitle.trimmingCharacters(in: .whitespaces).isEmpty)

                        Button("Cancel") {
                            isAddingCard = false
                            newCardTitle = ""
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal, AppTheme.spacingMD)
                .padding(.bottom, AppTheme.spacingMD)
                .transition(.opacity.combined(with: .offset(y: 4)))
            } else {
                Button {
                    isAddingCard = true
                    // Delay focus to allow transition
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isNewCardFocused = true
                    }
                } label: {
                    Label("Add Card", systemImage: "plus")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.accent)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: AppTheme.minTouchTarget)
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.horizontal, AppTheme.spacingMD)
                .padding(.bottom, AppTheme.spacingMD)
            }
        }
        .animation(reduceMotion ? nil : AppTheme.professionalSpring, value: isAddingCard)
    }

    // MARK: - Helpers

    private func submitNewCard() {
        let trimmed = newCardTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        withAnimation(reduceMotion ? nil : AppTheme.professionalSpring) {
            store.addCard(title: trimmed, to: list.id, in: boardID)
        }
        newCardTitle = ""
        isNewCardFocused = true
    }
}
