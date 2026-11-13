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

    /// StoreKit expects the numeric App Store identifier, never a bundle ID or a URL.
    var storeOverlayID: String? {
        guard appStoreURL != nil, !appStoreID.isEmpty,
              appStoreID.utf8.allSatisfy({ (48...57).contains($0) }),
              let value = UInt64(appStoreID), value > 0 else { return nil }
        return appStoreID
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

    /// The App Store genre, which the service gives in English, in the host app's language.
    var category: String { Self.category(for: genre, in: CroaResources.bundle) }

    /// `bundle` is the package's, or one of its `.lproj` folders to read a given language.
    /// A genre the catalog does not know keeps the service's name.
    static func category(for genre: String?, in bundle: Bundle) -> String {
        switch genre {
        case nil, "": String(localized: "Autres", bundle: bundle, comment: "Category of an app without an App Store genre")
        case "Games": String(localized: "Jeux", bundle: bundle, comment: "App Store category: Games")
        case "Productivity": String(localized: "Productivité", bundle: bundle, comment: "App Store category: Productivity")
        case "Developer Tools": String(localized: "Développement", bundle: bundle, comment: "App Store category: Developer Tools")
        case "Utilities": String(localized: "Utilitaires", bundle: bundle, comment: "App Store category: Utilities")
        case "Lifestyle": String(localized: "Style de vie", bundle: bundle, comment: "App Store category: Lifestyle")
        case "Entertainment": String(localized: "Divertissement", bundle: bundle, comment: "App Store category: Entertainment")
        case "Health & Fitness": String(localized: "Forme et santé", bundle: bundle, comment: "App Store category: Health & Fitness")
        case "Medical": String(localized: "Médecine", bundle: bundle, comment: "App Store category: Medical")
        case "Education": String(localized: "Éducation", bundle: bundle, comment: "App Store category: Education")
        case "Travel": String(localized: "Voyages", bundle: bundle, comment: "App Store category: Travel")
        case "Reference": String(localized: "Références", bundle: bundle, comment: "App Store category: Reference")
        case "Business": String(localized: "Économie et entreprise", bundle: bundle, comment: "App Store category: Business")
        case "Finance": String(localized: "Finance", bundle: bundle, comment: "App Store category: Finance")
        case "Music": String(localized: "Musique", bundle: bundle, comment: "App Store category: Music")
        case "Photo & Video": String(localized: "Photo et vidéo", bundle: bundle, comment: "App Store category: Photo & Video")
        case "Graphics & Design": String(localized: "Graphisme et design", bundle: bundle, comment: "App Store category: Graphics & Design")
        case "Social Networking": String(localized: "Réseaux sociaux", bundle: bundle, comment: "App Store category: Social Networking")
        case "Food & Drink": String(localized: "Cuisine", bundle: bundle, comment: "App Store category: Food & Drink")
        case "Navigation": String(localized: "Navigation", bundle: bundle, comment: "App Store category: Navigation")
        case "News": String(localized: "Actualités", bundle: bundle, comment: "App Store category: News")
        case "Shopping": String(localized: "Shopping", bundle: bundle, comment: "App Store category: Shopping")
        case "Sports": String(localized: "Sports", bundle: bundle, comment: "App Store category: Sports")
        case "Weather": String(localized: "Météo", bundle: bundle, comment: "App Store category: Weather")
        case "Books": String(localized: "Livres", bundle: bundle, comment: "App Store category: Books")
        case let genre?: genre
        }
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
