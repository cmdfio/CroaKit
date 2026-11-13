import Foundation

/// All artwork, the compiled Metal library and the string catalog belong to the package bundle.
/// SwiftUI reads a string literal from the host app's catalog unless it is given this bundle:
/// every visible string is a `Text("…", bundle: .module)` or a `String(localized:bundle:)`.
enum CroaResources {
    static let bundle = Bundle.module
}

struct CroaAppInfo: Sendable {
    let appName: String
    let version: String
    let build: String

    init(appName: String?, version: String?, build: String?, bundleValue: (String) -> String?) {
        func nonempty(_ value: String?) -> String? {
            guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !value.isEmpty else { return nil }
            return value
        }
        self.appName = nonempty(appName)
            ?? nonempty(bundleValue("CFBundleDisplayName"))
            ?? nonempty(bundleValue("CFBundleName"))
            ?? String(localized: "cette app", bundle: .module,
                      comment: "Stands for the app's name in “Merci d’utiliser %@” when the host app has none")
        self.version = nonempty(version) ?? nonempty(bundleValue("CFBundleShortVersionString")) ?? "—"
        self.build = nonempty(build) ?? nonempty(bundleValue("CFBundleVersion")) ?? "—"
    }
}
