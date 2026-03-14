import SwiftUI

// MARK: - AddBoardSheet
// Modal form for creating a new board with title and icon picker.

struct AddBoardSheet: View {
    @Environment(BoardStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var title = ""
    @State private var selectedIcon = "rectangle.on.rectangle"
    @FocusState private var isTitleFocused: Bool

    /// A curated set of SF Symbol icons for board selection
    private let iconOptions = [
        "rectangle.on.rectangle", "rocket.fill", "person.fill",
        "briefcase.fill", "house.fill", "star.fill",
        "heart.fill", "lightbulb.fill", "book.fill",
        "cart.fill", "gamecontroller.fill", "paintbrush.fill",
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Board title", text: $title)
                        .focused($isTitleFocused)
                } header: {
                    Text("Title")
                }

                Section {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: AppTheme.spacingSM) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Button {
                                withAnimation(reduceMotion ? nil : AppTheme.pressAnimation) {
                                    selectedIcon = icon
                                }
                            } label: {
                                Image(systemName: icon)
                                    .font(.title3)
                                    .frame(width: 44, height: 44)
                                    .foregroundStyle(selectedIcon == icon ? .white : AppTheme.primary)
                                    .background(selectedIcon == icon ? AppTheme.primary : AppTheme.listBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSM))
                            }
                            .buttonStyle(PressableButtonStyle())
                        }
                    }
                } header: {
                    Text("Icon")
                }
            }
            .navigationTitle("New Board")
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
                            store.addBoard(
                                title: title.trimmingCharacters(in: .whitespaces),
                                iconName: selectedIcon
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
