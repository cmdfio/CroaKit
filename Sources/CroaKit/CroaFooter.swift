import SwiftUI

/// System typography, customisable attribution, animated mascot, app version.
public struct CroaFooter: View {
    private let info: CroaAppInfo
    private let firstName: String
    private let frogWidth: CGFloat
    private let animationsEnabled: Bool

    public init(
        firstName: String,
        appName: String? = nil,
        version: String? = nil,
        build: String? = nil,
        frogWidth: CGFloat = 36.96,
        animationsEnabled: Bool = true
    ) {
        info = CroaAppInfo(appName: appName, version: version, build: build,
                           bundleValue: { Bundle.main.object(forInfoDictionaryKey: $0) as? String })
        self.firstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.frogWidth = frogWidth
        self.animationsEnabled = animationsEnabled
    }

    public var body: some View {
        VStack(spacing: 8) {
            Text(verbatim: "Merci d’utiliser \(info.appName)")
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(.primary)
            Text(verbatim: firstName.isEmpty
                 ? "Conçu par un membre des grenouilles francophiles."
                 : "Conçu par \(firstName), un membre des grenouilles francophiles.")
                .font(.system(.footnote))
                .foregroundStyle(.secondary)
            CroaFrog(width: frogWidth, animationsEnabled: animationsEnabled)
            Text(verbatim: "Version \(info.version) (\(info.build))")
                .font(.system(.caption))
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: 360)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("croakit.footer")
    }
}
