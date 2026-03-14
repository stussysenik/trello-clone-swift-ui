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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("boardSwitcher.viewMode") private var viewMode: ViewMode = .grid
    @State private var showAddBoard = false
    @State private var boardToDelete: Board?

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
        }
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
                    .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
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
                    .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
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
        .shadow(
            color: .black.opacity(isHovered ? 0.12 : 0.08),
            radius: isHovered ? 6 : 3,
            x: 0,
            y: isHovered ? 2 : 1
        )
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
