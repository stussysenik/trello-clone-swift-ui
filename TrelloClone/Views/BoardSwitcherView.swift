import SwiftUI

// MARK: - BoardSwitcherView
// Root view — shows all boards with NavigationStack routing.
// Supports three view modes (grid, list, compact) persisted via @AppStorage.
// Features:
// - Toolbar segmented picker for view mode switching
// - Context menus for board deletion
// - Materializing entry transitions for board cards
// - "New Board" button styled per layout mode

struct BoardSwitcherView: View {
    @Environment(BoardStore.self) private var store
    @Environment(ThemeStore.self) private var themeStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("boardSwitcher.viewMode") private var viewMode: ViewMode = .grid
    @State private var showAddBoard = false
    @State private var boardToDelete: Board?
    @State private var showThemePicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                switch viewMode {
                case .grid:
                    gridView
                case .list:
                    listView
                case .compact:
                    compactView
                }
            }
            .animation(reduceMotion ? nil : AppTheme.professionalSpring, value: viewMode)
            .background(AppTheme.background)
            .navigationTitle("Boards")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Picker("View Mode", selection: $viewMode) {
                        ForEach(ViewMode.allCases, id: \.self) { mode in
                            Image(systemName: mode.iconName)
                                .accessibilityLabel(mode.label)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    themeToggleButton
                }
            }
            .navigationDestination(for: UUID.self) { boardID in
                BoardView(boardID: boardID)
            }
            .navigationDestination(for: CardRoute.self) { route in
                CardDetailView(route: route)
            }
            .sheet(isPresented: $showAddBoard) {
                AddBoardSheet()
            }
            .confirmationDialog(
                "Delete \"\(boardToDelete?.title ?? "")\"?",
                isPresented: Binding(
                    get: { boardToDelete != nil },
                    set: { if !$0 { boardToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let board = boardToDelete {
                        withAnimation(reduceMotion ? nil : AppTheme.professionalSpring) {
                            store.deleteBoard(id: board.id)
                        }
                    }
                    boardToDelete = nil
                }
            } message: {
                Text("All lists and cards in this board will be deleted.")
            }
            .sheet(isPresented: $showThemePicker) {
                ThemePickerSheet()
                    .presentationDetents([.height(320)])
            }
        }
    }

    // MARK: - Theme Toggle

    private var themeToggleButton: some View {
        Button {
            showThemePicker = true
        } label: {
            Image(systemName: themeStore.mode.iconName)
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.primary)
                .frame(width: 32, height: 32)
                .background(AppTheme.cardSurface)
                .clipShape(Circle())
                .appShadow(.subtle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Theme: \(themeStore.mode.displayName)")
    }

    // MARK: - Grid View (default)

    private let gridColumns = [
        GridItem(.adaptive(minimum: 160), spacing: AppTheme.spacingLG)
    ]

    private var gridView: some View {
        LazyVGrid(columns: gridColumns, spacing: AppTheme.spacingLG) {
            ForEach(store.boards) { board in
                NavigationLink(value: board.id) {
                    BoardCard(board: board)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button(role: .destructive) {
                        boardToDelete = board
                    } label: {
                        Label("Delete Board", systemImage: "trash")
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity
                        .combined(with: .offset(y: AppTheme.entryOffset))
                        .combined(with: .scale(scale: 0.98)),
                    removal: .opacity
                        .combined(with: .scale(scale: AppTheme.minEntryScale))
                ))
            }

            // Add Board Card
            gridAddBoardCard
        }
        .padding(AppTheme.spacingLG)
    }

    // MARK: - List View

    private var listView: some View {
        LazyVStack(spacing: AppTheme.spacingSM) {
            ForEach(store.boards) { board in
                NavigationLink(value: board.id) {
                    HStack(spacing: AppTheme.spacingMD) {
                        Image(systemName: board.iconName)
                            .font(.title3)
                            .foregroundStyle(AppTheme.primary)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(board.title)
                                .font(.headline)
                                .foregroundStyle(AppTheme.textPrimary)
                                .lineLimit(1)
                            HStack(spacing: AppTheme.spacingSM) {
                                Label("\(board.lists.count) lists", systemImage: "list.bullet")
                                Label("\(board.totalCards) cards", systemImage: "note.text")
                            }
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(AppTheme.spacingMD)
                    .background(AppTheme.cardSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSM))
                    .appShadow(.card)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button(role: .destructive) {
                        boardToDelete = board
                    } label: {
                        Label("Delete Board", systemImage: "trash")
                    }
                }
            }

            // Add Board row
            listAddBoardButton
        }
        .padding(AppTheme.spacingLG)
    }

    // MARK: - Compact View

    private let compactColumns = [
        GridItem(.adaptive(minimum: 100), spacing: AppTheme.spacingSM)
    ]

    private var compactView: some View {
        LazyVGrid(columns: compactColumns, spacing: AppTheme.spacingSM) {
            ForEach(store.boards) { board in
                NavigationLink(value: board.id) {
                    VStack(spacing: AppTheme.spacingXS) {
                        Image(systemName: board.iconName)
                            .font(.title3)
                            .foregroundStyle(AppTheme.primary)

                        Text(board.title)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppTheme.textPrimary)
                            .lineLimit(1)

                        Text("\(board.totalCards)")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(AppTheme.cardSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSM))
                    .appShadow(.subtle)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button(role: .destructive) {
                        boardToDelete = board
                    } label: {
                        Label("Delete Board", systemImage: "trash")
                    }
                }
            }

            // Add Board compact tile
            compactAddBoardCard
        }
        .padding(AppTheme.spacingLG)
    }

    // MARK: - Add Board Buttons (per layout)

    private var gridAddBoardCard: some View {
        Button {
            showAddBoard = true
        } label: {
            VStack(spacing: AppTheme.spacingSM) {
                Image(systemName: "plus")
                    .font(.title)
                    .foregroundStyle(AppTheme.accent)
                Text("New Board")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.accent)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.radiusMD)
                    .strokeBorder(
                        AppTheme.accent.opacity(0.4),
                        style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                    )
            )
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var listAddBoardButton: some View {
        Button {
            showAddBoard = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(AppTheme.accent)
                Text("New Board")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.accent)
                Spacer()
            }
            .padding(AppTheme.spacingMD)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.radiusSM)
                    .strokeBorder(
                        AppTheme.accent.opacity(0.4),
                        style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                    )
            )
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var compactAddBoardCard: some View {
        Button {
            showAddBoard = true
        } label: {
            VStack(spacing: AppTheme.spacingXS) {
                Image(systemName: "plus")
                    .font(.title3)
                    .foregroundStyle(AppTheme.accent)
                Text("New")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.accent)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.radiusSM)
                    .strokeBorder(
                        AppTheme.accent.opacity(0.4),
                        style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                    )
            )
        }
        .buttonStyle(PressableButtonStyle())
    }
}

// MARK: - BoardCard
// Individual board tile in the switcher grid.
// On macOS: hover state with scale 1.02 + shadow lift.
// Full contentShape for tap area coverage.

struct BoardCard: View {
    let board: Board

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            Image(systemName: board.iconName)
                .font(.title2)
                .foregroundStyle(AppTheme.primary)

            Text(board.title)
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)

            HStack(spacing: AppTheme.spacingSM) {
                Label("\(board.lists.count)", systemImage: "list.bullet")
                Label("\(board.totalCards)", systemImage: "note.text")
            }
            .font(.caption)
            .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(AppTheme.spacingLG)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 140)
        .background(AppTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMD))
        .appShadow(isHovered ? .column : .card)
        .scaleEffect(isHovered ? AppTheme.hoverScale : 1.0)
        .animation(reduceMotion ? nil : AppTheme.hoverAnimation, value: isHovered)
        .contentShape(Rectangle())
        #if os(macOS)
        .onHover { hovering in
            isHovered = hovering
        }
        #endif
    }
}

// MARK: - ThemePickerSheet
// Bottom sheet for selecting the app theme mode.
// Shows three options: System, Light, and Dark.

struct ThemePickerSheet: View {
    @Environment(ThemeStore.self) private var themeStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: AppTheme.spacingLG) {
            // Handle bar
            RoundedRectangle(cornerRadius: 2.5)
                .fill(AppTheme.textSecondary.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, AppTheme.spacingSM)

            Text("Appearance")
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)

            VStack(spacing: AppTheme.spacingSM) {
                ForEach(ThemeMode.allCases) { mode in
                    ThemeOptionRow(
                        mode: mode,
                        isSelected: themeStore.mode == mode
                    ) {
                        withAnimation(reduceMotion ? nil : AppTheme.professionalSpring) {
                            themeStore.setMode(mode)
                        }
                        dismiss()
                    }
                }
            }
            .padding(.horizontal, AppTheme.spacingLG)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
    }
}

// MARK: - ThemeOptionRow

struct ThemeOptionRow: View {
    let mode: ThemeMode
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.spacingMD) {
                Image(systemName: mode.iconName)
                    .font(.title3)
                    .foregroundStyle(isSelected ? AppTheme.primary : AppTheme.textSecondary)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(isSelected ? AppTheme.primary.opacity(0.12) : AppTheme.listBackground)
                    )

                Text(mode.displayName)
                    .font(.body.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? AppTheme.textPrimary : AppTheme.textSecondary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.primary)
                        .transition(
                            .scale(scale: 0.8)
                            .combined(with: .opacity)
                        )
                }
            }
            .padding(AppTheme.spacingMD)
            .background(AppTheme.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMD))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusMD)
                    .stroke(
                        isSelected ? AppTheme.primary.opacity(0.5) : AppTheme.cardBorder,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(reduceMotion ? nil : AppTheme.pressAnimation, value: isSelected)
    }
}
