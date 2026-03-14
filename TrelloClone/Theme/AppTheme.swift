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

    // MARK: Tag Colors (OKLCH-based)
    //
    // Uses OKLCH perceptual color space for vibrant, evenly-spaced tag colors.
    // djb2 hash gives each tag a stable hue; golden-angle rotation ensures
    // adjacent tags in a card's list never share similar colors.

    /// Computes the djb2 hash hue for a tag string (0–360).
    /// Stable across launches unlike `String.hashValue`.
    static func tagHue(for tag: String) -> Double {
        var hash: UInt = 5381
        for byte in tag.utf8 {
            hash = ((hash &<< 5) &+ hash) &+ UInt(byte)
        }
        return Double(hash % 360)
    }

    /// Returns a single deterministic OKLCH Color for a tag string.
    static func tagColor(for tag: String) -> Color {
        Color.oklch(lightness: 0.72, chroma: 0.14, hue: tagHue(for: tag))
    }

    /// Returns colors for an ordered array of tags, guaranteeing adjacent
    /// tags (n and n+1) never share a similar hue. When two neighbors fall
    /// within 30° of each other, the second is rotated by the golden angle
    /// (137.508°) for maximum perceptual separation.
    static func tagColors(for tags: [String]) -> [Color] {
        guard !tags.isEmpty else { return [] }
        var colors: [Color] = []
        var prevHue: Double = -999 // sentinel so first tag is never shifted
        for tag in tags {
            let baseHue = tagHue(for: tag)
            var hue = baseHue
            let delta = abs(hue - prevHue).truncatingRemainder(dividingBy: 360)
            if min(delta, 360 - delta) < 30 {
                hue = (baseHue + 137.508).truncatingRemainder(dividingBy: 360)
            }
            colors.append(Color.oklch(lightness: 0.72, chroma: 0.14, hue: hue))
            prevHue = hue
        }
        return colors
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

    // MARK: Card Detail Typography (iA Writer-inspired)

    /// Large bold title for card detail view
    static let cardDetailTitleFont: Font = .system(.title, weight: .bold)

    /// Serif body font for card descriptions — iA Writer writing feel
    static let cardDetailBodyFont: Font = .system(.body, design: .serif)

    /// Generous line spacing for readable long-form text
    static let cardDetailBodyLineSpacing: CGFloat = 6

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

    /// Bouncy spring for drag-drop landing — playful but controlled
    static let bouncyDropSpring: Animation = .spring(duration: 0.4, bounce: 0.3)

    /// Pulsing border for active drop zones — loops while targeted
    static let dropZonePulseAnimation: Animation = .easeInOut(duration: 0.6).repeatForever(autoreverses: true)

    // MARK: Animation Values

    /// Entry/exit scale — never animate from 0
    static let minEntryScale: CGFloat = 0.9

    /// Subtle press sink for interactive elements
    static let pressScale: CGFloat = 0.97

    /// Materializing translateY offset
    static let entryOffset: CGFloat = 8

    /// Materializing blur radius
    static let entryBlur: CGFloat = 4

    /// Scale for element being dragged (lift effect)
    static let dragLiftScale: CGFloat = 1.05

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

// MARK: - OKLCH Color Extension
// Converts OKLCH (perceptual lightness, chroma, hue) to sRGB via the OKLab
// intermediate space. OKLCH provides perceptually uniform color spacing —
// equal chroma values look equally vivid regardless of hue.

extension Color {
    /// Creates a SwiftUI Color from OKLCH components.
    /// - Parameters:
    ///   - lightness: Perceptual lightness 0…1 (0 = black, 1 = white)
    ///   - chroma: Colorfulness 0…~0.37 (0 = gray)
    ///   - hue: Hue angle in degrees 0…360
    static func oklch(lightness L: Double, chroma C: Double, hue h: Double) -> Color {
        // OKLCH → OKLab
        let hRad = h * .pi / 180.0
        let a = C * cos(hRad)
        let b = C * sin(hRad)

        // OKLab → linear sRGB (using the OKLab→LMS→linear-sRGB matrix chain)
        let l_ = L + 0.3963377774 * a + 0.2158037573 * b
        let m_ = L - 0.1055613458 * a - 0.0638541728 * b
        let s_ = L - 0.0894841775 * a - 1.2914855480 * b

        let l = l_ * l_ * l_
        let m = m_ * m_ * m_
        let s = s_ * s_ * s_

        var r = +4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
        var g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
        var bl = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s

        // Clamp to sRGB gamut
        r = min(max(r, 0), 1)
        g = min(max(g, 0), 1)
        bl = min(max(bl, 0), 1)

        // Linear → sRGB gamma
        func gammaEncode(_ c: Double) -> Double {
            c <= 0.0031308 ? 12.92 * c : 1.055 * pow(c, 1.0 / 2.4) - 0.055
        }

        return Color(
            red: gammaEncode(r),
            green: gammaEncode(g),
            blue: gammaEncode(bl)
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
