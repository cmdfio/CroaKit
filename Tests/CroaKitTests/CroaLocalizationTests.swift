import Foundation
import Testing
@testable import CroaKit

/// French is the catalog's source language; the others are its translations.
private let languages = ["ar", "de", "en", "es", "fr", "it", "ja", "ko", "pt-BR", "zh-Hans"]

/// One language's compiled strings, whatever language the tests run in.
private func strings(in language: String) throws -> Bundle {
    let url = try #require(CroaResources.bundle.url(forResource: language, withExtension: "lproj"))
    return try #require(Bundle(url: url))
}

/// The keys a language's compiled tables hold: plain strings, and plurals.
private func keys(in language: String) throws -> Set<String> {
    let bundle = try strings(in: language)
    var keys = Set<String>()
    for table in ["strings", "stringsdict"] {
        guard let url = bundle.url(forResource: "Localizable", withExtension: table) else { continue }
        let entries = try #require(NSDictionary(contentsOf: url) as? [String: Any])
        keys.formUnion(entries.keys)
    }
    return keys
}

private func count(_ key: String, _ value: Int, in language: String) throws -> String {
    let format = try strings(in: language).localizedString(forKey: key, value: nil, table: nil)
    return String(format: format, locale: Locale(identifier: language), value)
}

@Test func packageBundleHoldsEveryLanguage() {
    #expect(Set(CroaResources.bundle.localizations) == Set(languages))
    #expect(CroaResources.bundle.developmentLocalization == "fr")
}

@Test(arguments: languages) func everyStringIsTranslated(language: String) throws {
    // French tables hold its plurals only: a source string is its own key.
    let source = try keys(in: "en")
    #expect(source.count == 71)
    guard language != "fr" else {
        #expect(try keys(in: "fr").isSubset(of: source))
        return
    }
    #expect(try keys(in: language) == source)
    let bundle = try strings(in: language)
    for key in source {
        let value = bundle.localizedString(forKey: key, value: "\u{0}", table: nil)
        #expect(value != "\u{0}" && !value.isEmpty, "\(language): \(key)")
    }
}

@Test func signatureKeepsTheCollectiveNameInEveryLanguage() throws {
    for language in languages where language != "fr" {
        let bundle = try strings(in: language)
        for key in ["Conçu par %@, un membre des grenouilles francophiles.",
                    "Conçu par un membre des grenouilles francophiles."] {
            let value = bundle.localizedString(forKey: key, value: nil, table: nil)
            #expect(value.contains("Grenouilles Francophiles"), "\(language): \(value)")
        }
        let version = bundle.localizedString(forKey: "Version %@ (%@)", value: nil, table: nil)
        #expect(String(format: version, "4.0", "50").contains("4.0") && version.contains("%2$@"))
    }
}

@Test func categoriesAndCountsFollowTheLanguage() throws {
    #expect(CroaCommunityApp.category(for: "Games", in: try strings(in: "fr")) == "Jeux")
    #expect(CroaCommunityApp.category(for: "Games", in: try strings(in: "en")) == "Games")
    #expect(CroaCommunityApp.category(for: "Games", in: try strings(in: "ja")) == "ゲーム")
    #expect(CroaCommunityApp.category(for: nil, in: try strings(in: "de")) == "Sonstige")
    #expect(CroaCommunityApp.category(for: "Unlisted Genre", in: try strings(in: "es")) == "Unlisted Genre")
    #expect(try count("%lld apps", 1, in: "fr") == "1 app")
    #expect(try count("%lld apps", 3, in: "fr") == "3 apps")
    #expect(try count("%lld apps", 1, in: "en") == "1 app")
    #expect(try count("%lld apps", 3, in: "en") == "3 apps")
    #expect(try count("%lld apps", 2, in: "ar") == "تطبيقان")
    #expect(try count("%lld avis", 1, in: "de") == "1 Bewertung")
    #expect(try count("%lld avis", 12, in: "de") == "12 Bewertungen")
    #expect(try count("%lld avis", 12, in: "fr") == "12 avis")
}
