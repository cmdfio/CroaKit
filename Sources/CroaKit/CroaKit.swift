import SwiftUI

/// A small signature for apps made by the Grenouilles Francophiles.
public enum CroaKit {
    /// Browse the apps approved by the ⌘+F community. Present in a sheet or a tab.
    @MainActor
    public static func communityApps(
        excludingAppStoreID: String? = nil,
        client: CroaCommunityClient = .init()
    ) -> CroaCommunityApps {
        CroaCommunityApps(excludingAppStoreID: excludingAppStoreID, client: client)
    }

    /// Reads the host app's name, version and build unless explicitly provided.
    /// Add this directly to a SwiftUI `VStack`, `ScrollView` or about screen.
    @MainActor
    public static func footer(
        firstName: String,
        appName: String? = nil,
        version: String? = nil,
        build: String? = nil,
        frogWidth: CGFloat = 36.96,
        animationsEnabled: Bool = true
    ) -> CroaFooter {
        CroaFooter(firstName: firstName, appName: appName, version: version,
                   build: build, frogWidth: frogWidth, animationsEnabled: animationsEnabled)
    }
}
