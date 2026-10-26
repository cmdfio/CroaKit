import SwiftUI

/// Customisable signature, animated mascot and app version.
public struct CroaFooter: View {
    private let info: CroaAppInfo
    private let firstName: String
    private let frogWidth: CGFloat
    private let animationsEnabled: Bool
    private let theme: CroaTheme
    @Environment(\.colorScheme) private var colorScheme

    public init(
        firstName: String,
        appName: String? = nil,
        version: String? = nil,
        build: String? = nil,
        frogWidth: CGFloat = 36.96,
        animationsEnabled: Bool = true,
        theme: CroaTheme = .system
    ) {
        info = CroaAppInfo(appName: appName, version: version, build: build,
                           bundleValue: { Bundle.main.object(forInfoDictionaryKey: $0) as? String })
        self.firstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.frogWidth = frogWidth
        self.animationsEnabled = animationsEnabled
        self.theme = theme
    }

    private var appearance: CroaResolvedTheme { theme.resolve(in: colorScheme) }

    public var body: some View {
        VStack(spacing: 8) {
            Text(verbatim: "Merci d’utiliser \(info.appName)")
                .font(appearance.font.font(.subheadline, weight: .medium))
            Text(verbatim: firstName.isEmpty
                 ? "Conçu par un membre des grenouilles francophiles."
                 : "Conçu par \(firstName), un membre des grenouilles francophiles.")
                .font(appearance.font.font(.footnote))
                .foregroundStyle(appearance.secondary)
            CroaFrog(width: frogWidth, animationsEnabled: animationsEnabled)
            Text(verbatim: "Version \(info.version) (\(info.build))")
                .font(appearance.font.font(.caption))
                .foregroundStyle(appearance.secondary)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: 360)
        .padding(appearance.background.hasFill ? 20 : 0)
        .frame(maxWidth: .infinity)
        .background(appearance.background.style)
        .modifier(CroaThemeStyle(appearance: appearance))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("croakit.footer")
    }
}
