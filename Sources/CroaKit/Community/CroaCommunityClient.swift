import Foundation

/// Read-only client. No API key, account or analytics are required.
public struct CroaCommunityClient: Sendable {
    public static let submissionURL = URL(string: "https://cmdf.io/fr/apps#proposer")!
    public static let catalogueURL = URL(string: "https://cmdf.io/fr/apps")!
    private let baseURL: URL
    private let session: URLSession

    /// `baseURL` can point to a compatible staging server. Requests use the server's HTTP cache policy.
    public init(baseURL: URL = URL(string: "https://cmdf.io")!, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    public func apps() async throws -> [CroaCommunityApp] {
        let apps: [CroaCommunityApp] = try await get(baseURL.appendingPathComponent("api/apps"))
        var identifiers = Set<String>()
        return apps.filter { identifiers.insert($0.appStoreID).inserted }
    }

    public func detail(for app: CroaCommunityApp) async throws -> CroaCommunityAppDetail {
        // A slug is a single URL path segment; never accept a path or query supplied as a slug.
        guard !app.slug.isEmpty, app.slug.utf8.allSatisfy({
            (97...122).contains($0) || (48...57).contains($0) || $0 == 45
        }) else { throw CroaCommunityError.invalidResponse }
        return try await get(baseURL.appendingPathComponent("api/apps").appendingPathComponent(app.slug))
    }

    private func get<Value: Decodable & Sendable>(_ url: URL) async throws -> Value {
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 20)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        try Task.checkCancellation()
        guard let response = response as? HTTPURLResponse else { throw CroaCommunityError.invalidResponse }
        guard (200..<300).contains(response.statusCode) else {
            throw CroaCommunityError.httpStatus(response.statusCode)
        }
        guard data.count <= 5_000_000 else { throw CroaCommunityError.invalidResponse }
        return try JSONDecoder().decode(Value.self, from: data)
    }
}

public enum CroaCommunityError: Error, Equatable, Sendable {
    case httpStatus(Int)
    case invalidResponse
}
