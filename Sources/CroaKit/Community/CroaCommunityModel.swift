import Foundation
import Observation

@MainActor @Observable
final class CroaCommunityModel {
    private(set) var apps: [CroaCommunityApp] = []
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    private(set) var failed = false
    var query = ""
    var category = ""
    var tag = ""
    private let client: CroaCommunityClient
    private let excludedID: String?

    init(client: CroaCommunityClient, excludingAppStoreID: String?) {
        self.client = client
        self.excludedID = excludingAppStoreID
    }

    var categories: [String] { Set(apps.map(\.category)).sorted { $0.localizedStandardCompare($1) == .orderedAscending } }
    var filteredApps: [CroaCommunityApp] {
        apps.filter { $0.matches(query) && (category.isEmpty || $0.category == category) && (tag.isEmpty || $0.tags.contains(tag)) }
    }
    var isFiltered: Bool { !query.isEmpty || !category.isEmpty || !tag.isEmpty }

    func resetFilters() { query = ""; category = ""; tag = "" }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        failed = false
        defer { isLoading = false }
        do {
            let loaded = try await client.apps()
            try Task.checkCancellation()
            apps = loaded.filter { $0.appStoreID != excludedID }
            hasLoaded = true
            if !category.isEmpty && !categories.contains(category) { category = "" }
        } catch is CancellationError {
            // Disappearing views cancel their requests without showing an error.
        } catch let error as URLError where error.code == .cancelled {
        } catch {
            failed = true
        }
    }
}
