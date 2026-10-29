import SwiftUI

/// Customisable signature, animated mascot and app version.
public struct CroaFooter: View {
    private let info: CroaAppInfo
    private let firstName: String
    private let frogWidth: CGFloat
    private let animationsEnabled: Bool
    private let theme: CroaTheme
    private let showsCommunityLink: Bool
    private let excludingAppStoreID: String?
    @State private var isCommunityPresented = false
    @Environment(\.colorScheme) private var colorScheme

    /// Set `showsCommunityLink` to add a secondary entry point to the community catalogue.
    /// Prefer a dedicated link in the host app's navigation or settings for discoverability.
    /// `excludingAppStoreID` hides the host app from the catalogue opened by this footer.
    public init(
        firstName: String,
        appName: String? = nil,
        version: String? = nil,
        build: String? = nil,
        frogWidth: CGFloat = 36.96,
        animationsEnabled: Bool = true,
        theme: CroaTheme = .system,
        showsCommunityLink: Bool = false,
        excludingAppStoreID: String? = nil
    ) {
        info = CroaAppInfo(appName: appName, version: version, build: build,
                           bundleValue: { Bundle.main.object(forInfoDictionaryKey: $0) as? String })
        self.firstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.frogWidth = frogWidth
        self.animationsEnabled = animationsEnabled
        self.theme = theme
        self.showsCommunityLink = showsCommunityLink
        self.excludingAppStoreID = excludingAppStoreID
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
            if showsCommunityLink {
                Button { isCommunityPresented = true } label: {
                    HStack(spacing: 4) {
                        Text("Les apps du collectif")
                        Image(systemName: "chevron.right")
                            .accessibilityHidden(true)
                    }
                    .font(appearance.font.font(.footnote))
                    .foregroundStyle(appearance.tint)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Ouvre le catalogue des apps de la communauté")
                .accessibilityIdentifier("croakit.footer.community")
            }
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
        .sheet(isPresented: $isCommunityPresented) {
            CroaKit.communityApps(excludingAppStoreID: excludingAppStoreID, theme: theme)
        }
    }
}
