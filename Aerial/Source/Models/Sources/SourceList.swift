//
//  SourceList.swift
//  Aerial
//
//  Created by Guillaume Louel on 01/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Foundation

struct SourceList {
    // This is the current one until next fall
    static let tvOS13 = Source(name: "tvOS 13",
                        description: "Apple TV screensavers from tvOS 13",
                        manifestUrl: "https://sylvan.apple.com/Aerials/resources-13.tar",
                        type: .tvOS12,
                        scenes: [.landscape, .city, .space, .sea])

    // Legacy sources
    static let tvOS12 = Source(name: "tvOS 12",
                        description: "Apple TV screensavers from tvOS 12",
                        manifestUrl: "https://sylvan.apple.com/Aerials/resources.tar",
                        type: .tvOS12,
                        scenes: [.landscape, .city, .space])

    static let tvOS11 = Source(name: "tvOS 11",
                        description: "Apple TV screensavers from tvOS 11",
                        manifestUrl: "https://sylvan.apple.com/Aerials/2x/entries.json",
                        type: .tvOS11,
                        scenes: [.landscape, .city])

    static let tvOS10 = Source(name: "tvOS 10",
                        description: "Apple TV screensavers from tvOS 10",
                        manifestUrl: "http://a1.phobos.apple.com/us/r1000/000/Features/atv/AutumnResources/videos/entries.json",
                        type: .tvOS10,
                        scenes: [.landscape, .city])

    static var list: [Source] {
        return [tvOS13, tvOS12, tvOS11, tvOS10] + foundSources
    }

    // This is where the magic happens
    static var foundSources: [Source] {
        print("foundSources")
        var sources: [Source] = []

        for folder in URL(fileURLWithPath: Cache.supportPath).subDirectories {
            if !folder.lastPathComponent.starts(with: "tvOS")
                && !folder.lastPathComponent.starts(with: "backups") {
                print("\(folder)")

                // If it's valid, let's add !
                if let source = loadManifest(url: folder) {
                    sources.append(source)
                }
            }
        }

        return sources
    }

    static func loadManifest(url: URL) -> Source? {
        // Let's make sure we have the required files
        if !areManifestPresent(url: url) {
            debugLog("manifests not present")
            return nil
        }

        do {
            let jsonData = try Data(contentsOf: url.appendingPathComponent("manifest.json"))
            if let manifest = try? newJSONDecoder().decode(Manifest.self, from: jsonData) {
                return Source(name: manifest.name,
                              description: manifest.manifestDescription,
                              manifestUrl: "local",
                              type: .local,
                              scenes: [.landscape])
            }
        } catch {
            errorLog("Could not open manifest for source at \(url)")
            return nil
        }

        return nil
    }

    static func areManifestPresent(url: URL) -> Bool {
        // For a source to be valid we at the very least need two things
        // manifest.json    <- a description of the source
        // entries.json     <- the classic video manifest
        return FileManager.default.fileExists(atPath: url.path.appending("/entries.json")) &&
           FileManager.default.fileExists(atPath: url.path.appending("/manifest.json"))
    }

}

// MARK: - Manifest JSON
struct Manifest: Codable {
    let name, manifestDescription: String

    enum CodingKeys: String, CodingKey {
        case name
        case manifestDescription = "description"
    }
}
