import SwiftUI

// MARK: - Theme Mode
// User-selectable theme preferences. System follows the device setting,
// while light and dark force a specific appearance regardless of system settings.

enum ThemeMode: String, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    var iconName: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

// MARK: - Theme Store
// Central theme manager using @Observable macro (iOS 17+).
// Persists user preference to UserDefaults and provides dynamic color scheme override.

@Observable
final class ThemeStore {
    
    // MARK: State
    
    /// Current theme mode - persisted across app launches
    var mode: ThemeMode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: Self.themeKey)
            applyTheme()
        }
    }
    
    /// The effective color scheme to apply (nil means system default)
    var colorScheme: ColorScheme? {
        switch mode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    
    // MARK: Keys
    
    private static let themeKey = "app.theme.mode"
    
    // MARK: Init
    
    init() {
        // Load saved preference or default to light mode
        let savedMode = UserDefaults.standard.string(forKey: Self.themeKey) ?? ""
        self.mode = ThemeMode(rawValue: savedMode) ?? .light
    }
    
    // MARK: - Theme Application
    
    /// Applies the current theme mode - called automatically when mode changes
    private func applyTheme() {
        // Theme is applied via the .preferredColorScheme modifier in the view hierarchy
        // This store just maintains the state
    }
    
    // MARK: - Convenience Methods
    
    func setMode(_ newMode: ThemeMode) {
        mode = newMode
    }
    
    func cycle() {
        let allCases = ThemeMode.allCases
        guard let currentIndex = allCases.firstIndex(of: mode) else { return }
        let nextIndex = (currentIndex + 1) % allCases.count
        mode = allCases[nextIndex]
    }
}

// MARK: - Environment Key
// Allows views to access the theme store via @Environment

private struct ThemeStoreKey: EnvironmentKey {
    static let defaultValue = ThemeStore()
}

extension EnvironmentValues {
    var themeStore: ThemeStore {
        get { self[ThemeStoreKey.self] }
        set { self[ThemeStoreKey.self] = newValue }
    }
}
