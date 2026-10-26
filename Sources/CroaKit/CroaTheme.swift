import SwiftUI

/// Shared appearance for the signature, catalogue and app details.
public enum CroaTheme {
    /// Native colours, system typography and a transparent signature background.
    case system
    /// Deep green, rounded typography and light text.
    case pond
    /// Cream paper, serif typography and blue ink.
    case paper
    /// Custom colours and typography. Register custom fonts in the host app.
    case custom(
        background: CroaBackground = .automatic,
        font: CroaFont = .system,
        tint: Color = .accentColor,
        foreground: Color = .primary,
        secondaryForeground: Color = .secondary,
        colorScheme: ColorScheme? = nil
    )

    func resolve(in scheme: ColorScheme) -> CroaResolvedTheme {
        switch self {
        case .system:
            CroaResolvedTheme(
                background: .automatic, font: .system,
                tint: scheme == .dark ? Color(red: 0.54, green: 0.87, blue: 0.69) : Color(red: 0.16, green: 0.43, blue: 0.29),
                foreground: .primary, secondary: .secondary, colorScheme: scheme
            )
        case .pond:
            CroaResolvedTheme(
                background: .color(Color(red: 0.09, green: 0.17, blue: 0.14)), font: .rounded,
                tint: Color(red: 0.65, green: 0.88, blue: 0.71),
                foreground: Color(red: 0.96, green: 0.97, blue: 0.89),
                secondary: Color(red: 0.72, green: 0.81, blue: 0.74), colorScheme: .dark
            )
        case .paper:
            CroaResolvedTheme(
                background: .color(Color(red: 0.98, green: 0.96, blue: 0.88)), font: .serif,
                tint: Color(red: 0.13, green: 0.24, blue: 0.45),
                foreground: Color(red: 0.13, green: 0.19, blue: 0.29),
                secondary: Color(red: 0.36, green: 0.39, blue: 0.43), colorScheme: .light
            )
        case let .custom(background, font, tint, foreground, secondary, preferredScheme):
            CroaResolvedTheme(background: background, font: font, tint: tint,
                              foreground: foreground, secondary: secondary,
                              colorScheme: preferredScheme ?? scheme)
        }
    }
}

/// The background painted by CroaKit, within the component's bounds.
public enum CroaBackground {
    /// Keep the native catalogue background; leave the signature transparent.
    case automatic
    /// Show the host view's background beneath the content.
    case transparent
    case color(Color)
    case gradient(LinearGradient)

    var style: AnyShapeStyle {
        switch self {
        case .automatic, .transparent: AnyShapeStyle(Color.clear)
        case .color(let color): AnyShapeStyle(color)
        case .gradient(let gradient): AnyShapeStyle(gradient)
        }
    }

    var isAutomatic: Bool {
        if case .automatic = self { return true }
        return false
    }

    var hasFill: Bool {
        switch self {
        case .automatic, .transparent: false
        case .color, .gradient: true
        }
    }
}

/// Font families that retain the semantic hierarchy and Dynamic Type scaling.
public enum CroaFont: Equatable, Sendable {
    case system, rounded, serif, monospaced
    /// The PostScript name of a font installed or registered by the host app.
    case custom(String)

    var design: Font.Design? {
        switch self {
        case .system: .default
        case .rounded: .rounded
        case .serif: .serif
        case .monospaced: .monospaced
        case .custom: nil
        }
    }

    func font(_ style: Font.TextStyle, weight: Font.Weight? = nil) -> Font {
        if case .custom(let name) = self {
            let base = Font.custom(name, size: baseSize(for: style), relativeTo: style)
            let resolvedWeight = weight ?? (style == .headline ? .semibold : nil)
            return resolvedWeight.map { base.weight($0) } ?? base
        }
        return .system(style, design: design, weight: weight)
    }

    private func baseSize(for style: Font.TextStyle) -> CGFloat {
        // Base sizes, before Dynamic Type is applied by Font.custom(relativeTo:).
        #if os(macOS)
        switch style {
        case .largeTitle: 26
        case .title: 22
        case .title2: 17
        case .title3: 15
        case .headline, .body: 13
        case .callout: 12
        case .subheadline: 11
        case .footnote, .caption, .caption2: 10
        default: 13
        }
        #else
        switch style {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .headline, .body: 17
        case .callout: 16
        case .subheadline: 15
        case .footnote: 13
        case .caption: 12
        case .caption2: 11
        default: 17
        }
        #endif
    }
}

struct CroaResolvedTheme {
    let background: CroaBackground
    let font: CroaFont
    let tint: Color
    let foreground: Color
    let secondary: Color
    let colorScheme: ColorScheme

    var surface: Color { foreground.opacity(0.06) }

    func textOnTint(in environment: EnvironmentValues) -> Color {
        var values = environment
        values.colorScheme = colorScheme
        let color = tint.resolve(in: values)
        func linear(_ value: Float) -> Double {
            let value = Double(value)
            return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        let luminance = 0.2126 * linear(color.red) + 0.7152 * linear(color.green) + 0.0722 * linear(color.blue)
        // Choose the higher-contrast text colour for the filled action buttons.
        return luminance > 0.179 ? .black : .white
    }
}

struct CroaThemeStyle: ViewModifier {
    let appearance: CroaResolvedTheme

    func body(content: Content) -> some View {
        content
            .font(appearance.font.font(.body))
            .fontDesign(appearance.font.design)
            .foregroundStyle(appearance.foreground)
            .tint(appearance.tint)
            .environment(\.colorScheme, appearance.colorScheme)
    }
}

/// Apply inside NavigationStack so the background also reaches its safe areas.
struct CroaCatalogueBackground: ViewModifier {
    let appearance: CroaResolvedTheme

    func body(content: Content) -> some View {
        if appearance.background.isAutomatic {
            content
        } else {
            content
                #if os(iOS)
                .containerBackground(appearance.background.style, for: .navigation)
                .toolbarBackground(Color.clear, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(appearance.colorScheme, for: .navigationBar)
                #else
                .background { Rectangle().fill(appearance.background.style).ignoresSafeArea() }
                #endif
        }
    }
}
