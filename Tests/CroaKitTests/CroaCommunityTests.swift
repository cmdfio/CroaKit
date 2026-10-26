import Foundation
import Testing
@testable import CroaKit

private let catalogueFixture = """
[
  {"id":"first","appStoreId":"123","slug":"cafe","name":"Café Notes","developer":"Élodie","genre":"Productivity","tags":["duo"],"artworkUrl":"https://example.org/icon.png","url":"https://apps.apple.com/fr/app/id123"},
  {"id":"second","appStoreId":"456","slug":"petit-jeu","name":"Petit jeu","developer":null,"genre":"Games","tags":[],"artworkUrl":null,"url":"https://apps.apple.com/fr/app/id456"}
]
"""

private final class CommunityStubState: @unchecked Sendable {
    private let lock = NSLock()
    private var response: (Int, Data) = (200, Data())
    private var requests: [URLRequest] = []

    func set(status: Int = 200, body: String) {
        lock.lock(); defer { lock.unlock() }
        response = (status, Data(body.utf8))
        requests = []
    }
    func receive(_ request: URLRequest) -> (Int, Data) {
        lock.lock(); defer { lock.unlock() }
        requests.append(request)
        return response
    }
    func recorded() -> [URLRequest] {
        lock.lock(); defer { lock.unlock() }
        return requests
    }
}

private final class CommunityURLProtocol: URLProtocol, @unchecked Sendable {
    static let state = CommunityStubState()
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let (status, data) = Self.state.receive(request)
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil,
                                       headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

@Suite(.serialized)
struct CroaCommunityTests {
    private func makeClient() -> CroaCommunityClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [CommunityURLProtocol.self]
        return CroaCommunityClient(baseURL: URL(string: "https://catalogue.example")!, session: URLSession(configuration: config))
    }

    @Test func catalogueContractAndRequest() async throws {
        CommunityURLProtocol.state.set(body: catalogueFixture)
        let apps = try await makeClient().apps()
        #expect(apps.map(\.slug) == ["cafe", "petit-jeu"])
        #expect(apps[0].appStoreID == "123")
        #expect(apps[0].artworkURL?.scheme == "https")
        #expect(apps[1].developer == nil && apps[1].artworkURL == nil)
        let request = try #require(CommunityURLProtocol.state.recorded().first)
        #expect(request.url?.absoluteString == "https://catalogue.example/api/apps")
        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test func duplicateStoreIDsKeepTheFirstAppInServerOrder() async throws {
        let repeated = catalogueFixture.replacingOccurrences(of: "\"456\"", with: "\"123\"")
        CommunityURLProtocol.state.set(body: repeated)
        let apps = try await makeClient().apps()
        #expect(apps.count == 1 && apps[0].name == "Café Notes")
    }

    @Test(arguments: [404, 429, 503]) func httpErrorsAreNotEmptyCatalogues(_ status: Int) async throws {
        CommunityURLProtocol.state.set(status: status, body: "{\"error\":\"unavailable\"}")
        await #expect(throws: CroaCommunityError.httpStatus(status)) { try await makeClient().apps() }
    }

    @Test func invalidJSONIsNotAnEmptyCatalogue() async {
        CommunityURLProtocol.state.set(body: "<html>Unavailable</html>")
        await #expect(throws: DecodingError.self) { try await makeClient().apps() }
    }

    @Test func emptyCatalogueIsValid() async throws {
        CommunityURLProtocol.state.set(body: "[]")
        let apps = try await makeClient().apps()
        #expect(apps.isEmpty)
    }

    @Test func unsafeLinksAndSlugsAreNotUsed() async throws {
        let invalid = catalogueFixture
            .replacingOccurrences(of: "https://example.org/icon.png", with: "file:///private/secret")
            .replacingOccurrences(of: "https://apps.apple.com/fr/app/id123", with: "https://apps.apple.com.evil.example/app/id123")
            .replacingOccurrences(of: "\"cafe\"", with: "\"../admin\"")
        let app = try #require(JSONDecoder().decode([CroaCommunityApp].self, from: Data(invalid.utf8)).first)
        #expect(app.artworkURL == nil)
        #expect(app.appStoreURL == nil)
        CommunityURLProtocol.state.set(body: "[]")
        await #expect(throws: CroaCommunityError.invalidResponse) { try await makeClient().detail(for: app) }
        #expect(CommunityURLProtocol.state.recorded().isEmpty)
    }

    @Test func detailContractUsesTheSelectedSlugAndFiltersScreenshots() async throws {
        let app = try #require(JSONDecoder().decode([CroaCommunityApp].self, from: Data(catalogueFixture.utf8)).first)
        let detailJSON = """
        {"id":"first","appStoreId":"123","slug":"cafe","name":"Café Notes","url":"https://apps.apple.com/app/id123",
         "description":"Vos notes","blurb":null,"price":"Gratuit","rating":4.5,"ratingCount":12,"version":"1.0",
         "screenshots":["https://example.org/one.png","javascript:alert(1)","https://example.org/one.png"],
         "ipadScreenshots":["https://example.org/two.png"],"futureField":"ignored"}
        """
        CommunityURLProtocol.state.set(body: detailJSON)
        let detail = try await makeClient().detail(for: app)
        #expect(detail.app.tags.isEmpty)
        #expect(detail.blurb == nil && detail.price == "Gratuit")
        #expect(detail.screenshotURLs.count == 2)
        #expect(CommunityURLProtocol.state.recorded().first?.url?.path == "/api/apps/cafe")
    }

    @Test @MainActor func filteringAndRefreshFailurePreserveTheCatalogue() async throws {
        let model = CroaCommunityModel(client: makeClient(), excludingAppStoreID: nil)
        CommunityURLProtocol.state.set(body: catalogueFixture)
        await model.load()
        #expect(model.hasLoaded && !model.failed && !model.isLoading)
        model.query = "cafe ELODIE"
        #expect(model.filteredApps.map(\.slug) == ["cafe"])
        model.category = "Jeux"
        #expect(model.filteredApps.isEmpty)
        model.resetFilters()
        model.tag = "duo"
        #expect(model.filteredApps.count == 1)
        model.resetFilters()
        CommunityURLProtocol.state.set(status: 503, body: "{}")
        await model.load()
        #expect(model.failed && !model.isLoading)
        #expect(model.apps.count == 2)
        #expect(model.filteredApps.map(\.slug) == ["cafe", "petit-jeu"])
    }

    @Test @MainActor func hostAppCanBeExcluded() async {
        CommunityURLProtocol.state.set(body: catalogueFixture)
        let model = CroaCommunityModel(client: makeClient(), excludingAppStoreID: "123")
        await model.load()
        #expect(model.apps.map(\.appStoreID) == ["456"])
        #expect(model.categories == ["Jeux"])
    }
}
