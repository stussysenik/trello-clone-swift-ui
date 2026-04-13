import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - App Theme
//
// Aesthetic: refined editorial minimalism. Warm paper in light mode,
// warm charcoal in dark mode. Inspired by iA Writer (restraint), Things
// (warmth), and Notion (clarity). Neutrals are tinted toward a warm
// amber hue (h≈85) so surfaces feel like paper, not sterile UI gray.
// Accent is a single calm indigo (h≈265) — the only pop of color.
//
// Every color token resolves dynamically to its light/dark variant at
// render time via a UIColor/NSColor trait provider. Call sites do NOT
// need to branch on `@Environment(\.colorScheme)`.

enum AppTheme {

    // MARK: Colors

    /// App canvas — the backdrop behind all content
    static let background = Color(
        light: .oklch(lightness: 0.983, chroma: 0.004, hue: 85),
        dark:  .oklch(lightness: 0.145, chroma: 0.008, hue: 85)
    )

    /// List column background — sits on the canvas, slightly tinted
    static let listBackground = Color(
        light: .oklch(lightness: 0.940, chroma: 0.006, hue: 85),
        dark:  .oklch(lightness: 0.190, chroma: 0.009, hue: 85)
    )

    /// Card surface — the most elevated flat surface
    static let cardSurface = Color(
        light: .oklch(lightness: 1.000, chroma: 0.000, hue: 85),
        dark:  .oklch(lightness: 0.225, chroma: 0.009, hue: 85)
    )

    /// Primary ink — titles, body text
    static let textPrimary = Color(
        light: .oklch(lightness: 0.180, chroma: 0.008, hue: 85),
        dark:  .oklch(lightness: 0.940, chroma: 0.006, hue: 85)
    )

    /// Secondary ink — captions, metadata, icons
    static let textSecondary = Color(
        light: .oklch(lightness: 0.500, chroma: 0.008, hue: 85),
        dark:  .oklch(lightness: 0.660, chroma: 0.007, hue: 85)
    )

    /// Hairline borders and dividers
    static let cardBorder = Color(
        light: .oklch(lightness: 0.900, chroma: 0.006, hue: 85),
        dark:  .oklch(lightness: 0.280, chroma: 0.008, hue: 85)
    )

    /// Brand — calm indigo (Things-adjacent, never garish)
    static let primary = Color(
        light: .oklch(lightness: 0.520, chroma: 0.180, hue: 265),
        dark:  .oklch(lightness: 0.660, chroma: 0.150, hue: 265)
    )

    /// Pressed / emphasized brand
    static let primaryDark = Color(
        light: .oklch(lightness: 0.360, chroma: 0.160, hue: 265),
        dark:  .oklch(lightness: 0.520, chroma: 0.160, hue: 265)
    )

    /// Accent — interactive highlights, focus rings
    static let accent = Color(
        light: .oklch(lightness: 0.560, chroma: 0.180, hue: 265),
        dark:  .oklch(lightness: 0.700, chroma: 0.150, hue: 265)
    )

    /// Drop target highlight — translucent accent tint
    static let dropHighlight = Color(
        light: Color.oklch(lightness: 0.560, chroma: 0.180, hue: 265).opacity(0.12),
        dark:  Color.oklch(lightness: 0.700, chroma: 0.150, hue: 265).opacity(0.18)
    )

    /// Shadow tint — subtle in light, absent in dark.
    /// Dark mode uses surface-lightness contrast for elevation instead
    /// of drop shadows (Things / Notion convention).
    static let shadowColor = Color(
        light: Color.black.opacity(0.07),
        dark:  Color.clear
    )

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
    /// Tag colors stay consistent across light and dark themes so that
    /// a tag named "urgent" feels the same object in both modes.
    static func tagColor(for tag: String) -> Color {
        Color.oklch(lightness: 0.68, chroma: 0.13, hue: tagHue(for: tag))
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
            colors.append(Color.oklch(lightness: 0.68, chroma: 0.13, hue: hue))
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

// MARK: - Dynamic Light/Dark Color
// Creates a Color that resolves to one value in light mode and another
// in dark mode via the platform's native trait-change machinery.
// Resolution happens during rendering — no environment reads, no view
// invalidation, no @State. The SwiftUI render pass just asks the
// UIColor/NSColor for its current value.

extension Color {
    /// Returns a dynamic Color that resolves to `light` or `dark` based on
    /// the current system appearance.
    init(light: Color, dark: Color) {
        #if canImport(UIKit)
        let lightUI = UIColor(light)
        let darkUI  = UIColor(dark)
        self.init(UIColor { trait in
            trait.userInterfaceStyle == .dark ? darkUI : lightUI
        })
        #elseif canImport(AppKit)
        let lightNS = NSColor(light)
        let darkNS  = NSColor(dark)
        self.init(NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(
                from: [.aqua, .darkAqua, .vibrantLight, .vibrantDark]
            ) == .darkAqua
                || appearance.name == .darkAqua
                || appearance.name == .vibrantDark
            return isDark ? darkNS : lightNS
        })
        #else
        self = light
        #endif
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

// MARK: - Shadow Conveniences
// Elevation tokens that emit correct shadows in light and vanish in dark.
// Dark mode expresses elevation through surface lightness steps
// (cardSurface is brighter than listBackground which is brighter than
// background). Call sites use `.appShadow(.card)` instead of hand-rolling
// `.shadow(color: .black.opacity(0.08), ...)`.

extension View {
    /// Applies an elevation-aware shadow. No-op in dark mode.
    func appShadow(_ style: AppTheme.Elevation) -> some View {
        self.shadow(
            color: AppTheme.shadowColor,
            radius: style.radius,
            x: 0,
            y: style.offsetY
        )
    }
}

extension AppTheme {
    /// Elevation levels — resolve to subtle drop shadows in light mode
    /// and disappear in dark mode (where surface lightness steps do the work).
    enum Elevation {
        case subtle   // small chips, attached elements
        case card     // cards, pressable tiles
        case column   // list columns, raised panels
        case floating // drag previews, modals

        var radius: CGFloat {
            switch self {
            case .subtle:   return 2
            case .card:     return 3
            case .column:   return 6
            case .floating: return 8
            }
        }

        var offsetY: CGFloat {
            switch self {
            case .subtle:   return 1
            case .card:     return 1
            case .column:   return 2
            case .floating: return 4
            }
        }
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
