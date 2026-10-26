import Foundation

/// An approved app explicitly enabled for CroaKit by the cmdf.io team.
public struct CroaCommunityApp: Decodable, Identifiable, Hashable, Sendable {
    public let id: String
    public let appStoreID: String
    public let slug: String
    public let name: String
    public let developer: String?
    public let genre: String?
    public let tags: [String]
    private let artworkUrl: String?
    private let url: String

    public var artworkURL: URL? { Self.httpsURL(artworkUrl) }
    public var appStoreURL: URL? {
        guard let link = Self.httpsURL(url), link.host?.lowercased() == "apps.apple.com" else { return nil }
        return link
    }
    public var communityURL: URL {
        URL(string: "https://cmdf.io/fr/apps")!.appendingPathComponent(slug)
    }

    enum CodingKeys: String, CodingKey {
        case id, slug, name, developer, genre, tags, artworkUrl, url
        case appStoreID = "appStoreId"
    }

    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        appStoreID = try values.decode(String.self, forKey: .appStoreID)
        slug = try values.decode(String.self, forKey: .slug)
        name = try values.decode(String.self, forKey: .name)
        developer = try values.decodeIfPresent(String.self, forKey: .developer)
        genre = try values.decodeIfPresent(String.self, forKey: .genre)
        tags = try values.decodeIfPresent([String].self, forKey: .tags) ?? []
        artworkUrl = try values.decodeIfPresent(String.self, forKey: .artworkUrl)
        url = try values.decode(String.self, forKey: .url)
    }

    static func httpsURL(_ value: String?) -> URL? {
        guard let value, let url = URL(string: value), url.scheme?.lowercased() == "https",
              let host = url.host, !host.isEmpty, url.user == nil, url.password == nil else { return nil }
        return url
    }

    var category: String {
        let translations = [
            "Games": "Jeux", "Productivity": "Productivité", "Developer Tools": "Développement",
            "Utilities": "Utilitaires", "Lifestyle": "Style de vie", "Entertainment": "Divertissement",
            "Health & Fitness": "Forme et santé", "Medical": "Médecine", "Education": "Éducation",
            "Travel": "Voyages", "Reference": "Références", "Business": "Économie et entreprise",
            "Finance": "Finance", "Music": "Musique", "Photo & Video": "Photo et vidéo",
            "Graphics & Design": "Graphisme et design", "Social Networking": "Réseaux sociaux",
            "Food & Drink": "Cuisine", "Navigation": "Navigation", "News": "Actualités",
            "Shopping": "Shopping", "Sports": "Sports", "Weather": "Météo", "Books": "Livres"
        ]
        guard let genre, !genre.isEmpty else { return "Autres" }
        return translations[genre] ?? genre
    }

    func matches(_ query: String) -> Bool {
        let words = query.split(whereSeparator: \.isWhitespace)
        let text = [name, developer ?? "", genre ?? "", category].joined(separator: " ")
        return words.allSatisfy {
            text.range(of: String($0), options: [.caseInsensitive, .diacriticInsensitive],
                       locale: Locale(identifier: "fr")) != nil
        }
    }
}

/// Public details fetched only when an app is opened.
public struct CroaCommunityAppDetail: Decodable, Sendable {
    public let app: CroaCommunityApp
    public let description: String?
    public let blurb: String?
    public let price: String?
    public let rating: Double?
    public let ratingCount: Int?
    public let version: String?
    private let screenshots: [String]
    private let ipadScreenshots: [String]

    public var screenshotURLs: [URL] {
        var seen = Set<URL>()
        return (screenshots + ipadScreenshots).compactMap(CroaCommunityApp.httpsURL)
            .filter { seen.insert($0).inserted }.prefix(10).map { $0 }
    }

    enum CodingKeys: String, CodingKey {
        case description, blurb, price, rating, ratingCount, version, screenshots, ipadScreenshots
    }

    public init(from decoder: any Decoder) throws {
        app = try CroaCommunityApp(from: decoder)
        let values = try decoder.container(keyedBy: CodingKeys.self)
        description = try values.decodeIfPresent(String.self, forKey: .description)
        blurb = try values.decodeIfPresent(String.self, forKey: .blurb)
        price = try values.decodeIfPresent(String.self, forKey: .price)
        rating = try values.decodeIfPresent(Double.self, forKey: .rating)
        ratingCount = try values.decodeIfPresent(Int.self, forKey: .ratingCount)
        version = try values.decodeIfPresent(String.self, forKey: .version)
        screenshots = try values.decodeIfPresent([String].self, forKey: .screenshots) ?? []
        ipadScreenshots = try values.decodeIfPresent([String].self, forKey: .ipadScreenshots) ?? []
    }
}
