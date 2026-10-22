import Testing
import Metal
import SwiftUI
@testable import CroaKit
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@Test func hostMetadataAndOverrides() {
    let host = ["CFBundleDisplayName": "Mon app", "CFBundleName": "InternalName",
                "CFBundleShortVersionString": "2.4", "CFBundleVersion": "31"]
    let automatic = CroaAppInfo(appName: nil, version: nil, build: nil) { host[$0] }
    #expect(automatic.appName == "Mon app")
    #expect(automatic.version == "2.4")
    #expect(automatic.build == "31")
    let explicit = CroaAppInfo(appName: " Autre app ", version: "3.0", build: "7") { host[$0] }
    #expect(explicit.appName == "Autre app")
    #expect(explicit.version == "3.0")
    #expect(explicit.build == "7")
    let fallback = CroaAppInfo(appName: " ", version: nil, build: nil) {
        $0 == "CFBundleName" ? "Nom interne" : ""
    }
    #expect(fallback.appName == "Nom interne")
    #expect(fallback.version == "—")
    #expect(fallback.build == "—")
}

@Test @MainActor func publicEntryPointsAndPackagedArtwork() throws {
    _ = CroaKit.footer(firstName: "Clément")
    _ = CroaFooter(firstName: "Camille", appName: "Autre app", version: "1.2", build: "8")
    _ = CroaFrog(width: 72, animationsEnabled: false)
    #expect(CroaResources.bundle.bundleURL != Bundle.main.bundleURL)
    for name in ["FrancophileFrogRig", "FrancophileFrogLeftEye", "FrancophileFrogEye", "FrancophileFrogCroakPuffs"] {
        #if canImport(UIKit)
        #expect(UIImage(named: name, in: CroaResources.bundle, compatibleWith: nil) != nil)
        #elseif canImport(AppKit)
        #expect(CroaResources.bundle.image(forResource: name) != nil)
        #endif
    }
}

@Test func metalLibraryLivesInPackage() throws {
    let device = try #require(MTLCreateSystemDefaultDevice())
    let library = try device.makeDefaultLibrary(bundle: CroaResources.bundle)
    #expect(library.functionNames.contains("croaFrogSoftMotion"))
}

@Test func jumpResourcesPreserveSharedSeams() throws {
    let artwork = try #require(FrogJumpArtwork.shared)
    let body = try #require(artwork.layers.firstIndex { $0.name == "body" })
    let chest = try #require(artwork.layers.firstIndex { $0.name == "chest" })
    #expect(artwork.layers[body].stroke == 14)
    #expect(artwork.layers[chest].stroke == 0)
    #expect(artwork.indices.first == 0 && artwork.indices.last == 0)
    for (a, b) in zip(artwork.indices, artwork.indices.dropFirst()) {
        let transition = try #require(artwork.transitions["\(a)-\(b)"])
        for endpoint in 0...1 {
            let outside = transition[body][endpoint], cream = transition[chest][endpoint]
            #expect(outside[0] == cream[0])
            #expect(outside[191] == cream[95])
            #expect(Array(outside.dropFirst(192)) == Array(cream.dropFirst(96)))
        }
        for layer in transition {
            #expect(layer[0].count == layer[1].count)
            let finite = layer.flatMap { $0 }.flatMap { $0 }.allSatisfy { $0.isFinite }
            #expect(finite)
        }
    }
}
