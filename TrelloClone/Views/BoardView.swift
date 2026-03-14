import SwiftUI

// MARK: - BoardView
// Horizontal scrolling view of all lists in a board.
// Uses GeometryReader for responsive list width (85% on compact, 280pt on regular).
// Shows empty state when no lists exist.
// All transitions use materializing pattern (opacity + offset) with professional spring.

struct BoardView: View {
    let boardID: UUID
    @Environment(BoardStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showAddList = false

    private var board: Board? {
        store.boards.first { $0.id == boardID }
    }

    var body: some View {
        Group {
            if let board {
                if board.lists.isEmpty {
                    // Empty state
                    ContentUnavailableView(
                        "No Lists Yet",
                        systemImage: "list.bullet.rectangle",
                        description: Text("Tap + to create your first list")
                    )
                } else {
                    GeometryReader { geometry in
                        let computedWidth = AppTheme.listWidth(in: geometry)

                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(alignment: .top, spacing: AppTheme.spacingLG) {
                                ForEach(board.lists) { list in
                                    ListView(boardID: boardID, list: list, listWidth: computedWidth)
                                        .transition(.asymmetric(
                                            insertion: .opacity
                                                .combined(with: .offset(x: AppTheme.entryOffset)),
                                            removal: .opacity
                                                .combined(with: .scale(scale: AppTheme.minEntryScale))
                                        ))
                                }

                                // MARK: Add List Button
                                addListButton(width: computedWidth)
                            }
                            .padding(AppTheme.spacingLG)
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    "Board Not Found",
                    systemImage: "exclamationmark.triangle",
                    description: Text("This board may have been deleted.")
                )
            }
        }
        .background(AppTheme.background)
        .navigationTitle(board?.title ?? "Board")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddList = true
                } label: {
                    Label("Add List", systemImage: "plus.rectangle.on.rectangle")
                }
            }
        }
        .sheet(isPresented: $showAddList) {
            AddListSheet(boardID: boardID)
        }
    }

    // MARK: - Add List Button

    private func addListButton(width: CGFloat) -> some View {
        Button {
            showAddList = true
        } label: {
            VStack(spacing: AppTheme.spacingSM) {
                Image(systemName: "plus")
                    .font(.title2)
                Text("Add List")
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(AppTheme.accent)
            .frame(width: width, height: 120)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.radiusMD)
                    .strokeBorder(AppTheme.accent.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
            )
        }
        .buttonStyle(PressableButtonStyle())
    }
}
