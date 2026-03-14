import SwiftUI

// MARK: - AddListSheet
// Compact modal form for creating a new list in a board.

struct AddListSheet: View {
    let boardID: UUID
    @Environment(BoardStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var title = ""
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("List title", text: $title)
                        .focused($isTitleFocused)
                } header: {
                    Text("Title")
                }
            }
            .navigationTitle("New List")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        withAnimation(reduceMotion ? nil : AppTheme.professionalSpring) {
                            store.addList(
                                title: title.trimmingCharacters(in: .whitespaces),
                                to: boardID
                            )
                        }
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .presentationDetents([.medium])
            .onAppear { isTitleFocused = true }
        }
    }
}
