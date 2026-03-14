import SwiftUI

// MARK: - App Theme
// Centralized design tokens for the Trello clone.
// Uses a constrained blue + white palette inspired by Material Design blues.

enum AppTheme {

    // MARK: Colors

    /// Deep blue — primary brand color used for headers and CTAs
    static let primary = Color(hex: 0x1A73E8)

    /// Navy — darker variant for emphasis and pressed states
    static let primaryDark = Color(hex: 0x0D47A1)

    /// Light blue tint — list column background
    static let listBackground = Color(hex: 0xE8F0FE)

    /// Blue-gray — app canvas background
    static let background = Color(hex: 0xF0F4F8)

    /// Pure white — card surface
    static let cardSurface = Color.white

    /// Bright blue — accent for interactive elements and highlights
    static let accent = Color(hex: 0x4285F4)

    /// Navy text — primary readable text
    static let textPrimary = Color(hex: 0x1A237E)

    /// Medium gray — secondary / caption text
    static let textSecondary = Color(hex: 0x5F6B7A)

    /// Light border — card and divider strokes
    static let cardBorder = Color(hex: 0xDAE0E8)

    /// Drop target highlight — accent at 15% opacity
    static let dropHighlight = Color(hex: 0x4285F4).opacity(0.15)

    // MARK: Tag Palette

    /// 8 fixed colors for text-based tags — deterministic via djb2 hash
    static let tagPalette: [UInt] = [
        0xE53935, // Red
        0xF4511E, // Deep Orange
        0xFB8C00, // Orange
        0x43A047, // Green
        0x039BE5, // Light Blue
        0x5E35B1, // Deep Purple
        0x8E24AA, // Purple
        0x00897B, // Teal
    ]

    /// Returns a deterministic Color for a tag string using djb2 hash.
    /// Unlike `String.hashValue`, djb2 is stable across launches.
    static func tagColor(for tag: String) -> Color {
        var hash: UInt = 5381
        for byte in tag.utf8 {
            hash = ((hash &<< 5) &+ hash) &+ UInt(byte) // hash * 33 + byte
        }
        let hex = tagPalette[Int(hash % UInt(tagPalette.count))]
        return Color(hex: hex)
    }

    // MARK: Spacing

    /// 4pt — extra-small spacing
    static let spacingXS: CGFloat = 4

    /// 8pt — small spacing
    static let spacingSM: CGFloat = 8

    /// 12pt — medium spacing
    static let spacingMD: CGFloat = 12

    /// 16pt — large spacing
    static let spacingLG: CGFloat = 16

    /// 24pt — extra-large spacing
    static let spacingXL: CGFloat = 24

    // MARK: Corner Radius

    static let radiusSM: CGFloat = 6
    static let radiusMD: CGFloat = 10
    static let radiusLG: CGFloat = 14

    // MARK: Sizes

    /// Fixed width for list columns — fallback for drag previews
    static let listWidth: CGFloat = 280

    /// Responsive list width: 85% of screen on compact (<500pt), 280pt on regular
    static func listWidth(in geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        return screenWidth < 500 ? screenWidth * 0.85 : 280
    }

    /// Minimum touch target per Apple HIG (44pt)
    static let minTouchTarget: CGFloat = 44

    // MARK: Animation

    /// Primary mutation animation — professional, no bounce (Emil Kowalski "Restraint & Speed")
    static let professionalSpring: Animation = .spring(duration: 0.45, bounce: 0)

    /// Fast spring for drag-drop moves
    static let fastSpring: Animation = .spring(duration: 0.25, bounce: 0)

    /// Button/card press feedback — quick easeInOut
    static let pressAnimation: Animation = .easeInOut(duration: 0.15)

    /// macOS hover state animation
    static let hoverAnimation: Animation = .easeInOut(duration: 0.18)

    /// Drop zone highlight animation
    static let dropTargetAnimation: Animation = .easeInOut(duration: 0.2)

    // MARK: Animation Values

    /// Entry/exit scale — never animate from 0
    static let minEntryScale: CGFloat = 0.9

    /// Subtle press sink for interactive elements
    static let pressScale: CGFloat = 0.97

    /// Materializing translateY offset
    static let entryOffset: CGFloat = 8

    /// Materializing blur radius
    static let entryBlur: CGFloat = 4

    /// macOS hover lift scale
    static let hoverScale: CGFloat = 1.02

    // MARK: Shadows

    /// Subtle shadow for cards
    static let cardShadow = ShadowStyle.drop(
        color: Color.black.opacity(0.08),
        radius: 3,
        x: 0,
        y: 1
    )

    /// Slightly stronger shadow for list columns
    static let listShadow = ShadowStyle.drop(
        color: Color.black.opacity(0.1),
        radius: 6,
        x: 0,
        y: 2
    )
}

// MARK: - Color Hex Initializer
// Convenience extension to create SwiftUI Colors from hex integer literals.

extension Color {
    /// Creates a Color from a hex integer, e.g. `Color(hex: 0x1A73E8)`.
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}

// MARK: - PressableButtonStyle
// Subtle scale-down on press for interactive elements.
// Respects Reduce Motion accessibility setting.

struct PressableButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? AppTheme.pressScale : 1.0)
            .animation(reduceMotion ? nil : AppTheme.pressAnimation,
                       value: configuration.isPressed)
    }
}
