import Foundation

/// All artwork and the compiled Metal library belong to the package bundle.
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
            ?? nonempty(bundleValue("CFBundleName")) ?? "cette app"
        self.version = nonempty(version) ?? nonempty(bundleValue("CFBundleShortVersionString")) ?? "—"
        self.build = nonempty(build) ?? nonempty(bundleValue("CFBundleVersion")) ?? "—"
    }
}
