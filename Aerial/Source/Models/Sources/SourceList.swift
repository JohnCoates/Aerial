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
                        scenes: [.nature, .city, .space, .sea],
                        isCachable: true)

    // Legacy sources
    static let tvOS12 = Source(name: "tvOS 12",
                        description: "Apple TV screensavers from tvOS 12",
                        manifestUrl: "https://sylvan.apple.com/Aerials/resources.tar",
                        type: .tvOS12,
                        scenes: [.nature, .city, .space],
                        isCachable: true)

    static let tvOS11 = Source(name: "tvOS 11",
                        description: "Apple TV screensavers from tvOS 11",
                        manifestUrl: "https://sylvan.apple.com/Aerials/2x/entries.json",
                        type: .tvOS11,
                        scenes: [.nature, .city],
                        isCachable: true)

    static let tvOS10 = Source(name: "tvOS 10",
                        description: "Apple TV screensavers from tvOS 10",
                        manifestUrl: "http://a1.phobos.apple.com/us/r1000/000/Features/atv/AutumnResources/videos/entries.json",
                        type: .tvOS10,
                        scenes: [.nature, .city],
                        isCachable: true)

    static var list: [Source] = [tvOS13, tvOS12, tvOS11, tvOS10] + foundSources

    // This is where the magic happens
    static var foundSources: [Source] {
        var sources: [Source] = []

        for folder in URL(fileURLWithPath: Cache.supportPath).subDirectories {
            if !folder.lastPathComponent.starts(with: "tvOS")
                && !folder.lastPathComponent.starts(with: "backups")
                && !folder.lastPathComponent.starts(with: "Thumbnails")
                && !folder.lastPathComponent.starts(with: "Cache") {

                // If it's valid, let's add !
                if let source = loadManifest(url: folder) {
                    print("source")
                    sources.append(source)
                } else if let newsources = loadMetaManifest(url: folder) {
                    print("sources")
                    sources.append(contentsOf: newsources)
                }
            }
        }

        return sources
    }

    static func fetchOnlineManifest(url: URL) {
        if let source = loadManifest(url: url) {
            debugLog("Source loaded")
            // Then save !
            let downloadManager = DownloadManager()
            downloadManager.queueDownload(url.appendingPathComponent("manifest.json"), folder: source.name)

            downloadManager.queueDownload(URL(string: source.manifestUrl)!, folder: source.name)
            list.append(source)

            source.setEnabled(true) // This will reload the main video list
        } else if let sources = loadMetaManifest(url: url) {
            debugLog("Sources loaded")

            for source in sources {
                // Then save !
                saveSource(source)

                let downloadManager = DownloadManager()
                downloadManager.queueDownload(URL(string: source.manifestUrl)!, folder: source.name)
                list.append(source)

                source.setEnabled(true) // This will reload the main video list
            }
        } else {
            Aerial.showErrorAlert(question: "No videos found", text: "Could not find any video at the URL you provided, please try again.")
        }
    }

    static func saveSource(_ source: Source) {
        // First make the folder
        FileHelpers.createDirectory(atPath: Cache.supportPath.appending("/"+source.name))

        let json = try? JSONEncoder().encode(source)

        do {
            print(Cache.supportPath.appending("/"+source.name+"/manifest.json"))
            try json!.write(to: URL(fileURLWithPath:
                                    Cache.supportPath.appending("/"+source.name+"/manifest.json")))
        } catch {
            errorLog("Can't save local source : \(error.localizedDescription)")
        }
    }

    static func loadMetaManifest(url: URL) -> [Source]? {
        // Let's make sure we have the required files
        if !areManifestPresent(url: url) && !url.absoluteString.starts(with: "http") {
            return nil
        }

        do {
            let jsonData = try Data(contentsOf: url.appendingPathComponent("manifest.json"))

            if let metamanifest = try? newJSONDecoder().decode(MetaManifest.self, from: jsonData) {
                var sources: [Source] = []

                for manifest in metamanifest.sources {
                    sources.append(parseSourceFromManifest(manifest, url: url))
                }

                return sources
            }
        } catch {
            errorLog("Could not open manifest for source at \(url)")
            return nil
        }

        return nil
    }

    static func loadManifest(url: URL) -> Source? {
        // Let's make sure we have the required files
        if !areManifestPresent(url: url) && !url.absoluteString.starts(with: "http") {
            return nil
        }

        do {
            let jsonData = try Data(contentsOf: url.appendingPathComponent("manifest.json"))
            if let manifest = try? newJSONDecoder().decode(Manifest.self, from: jsonData) {
                return parseSourceFromManifest(manifest, url: nil)
            }
        } catch {
            errorLog("Could not open manifest for source at \(url)")
            return nil
        }

        return nil
    }

    static private func parseSourceFromManifest(_ manifest: Manifest, url: URL?) -> Source {
        var local = true
        var mURL: String
        if let isLocal = manifest.local {
            local = isLocal
        }

        if local {
            mURL = (url != nil) ? url!.absoluteString : manifest.manifestUrl ?? ""
        } else {
            mURL = manifest.manifestUrl ?? ""
        }

        let cacheable: Bool = manifest.cacheable ?? !local

        return Source(name: manifest.name,
                      description: manifest.manifestDescription,
                      manifestUrl: mURL,
                      type: local ? .local : .tvOS12,
                      scenes: jsonToSceneArray(array: manifest.scenes ?? []),
                      isCachable: cacheable)
    }

    /// Helper to convert an array of strings to an array of sources
    ///
    /// ["landscape"] -> [.landscape]
    static func jsonToSceneArray(array: [String]) -> [SourceScene] {
        var output: [SourceScene] = []
        for scene in array {
            switch scene {
            case "sea":
                output.append(.sea)
            case "space":
                output.append(.space)
            case "city":
                output.append(.city)
            case "beach":
                output.append(.beach)
            case "countryside":
                output.append(.countryside)
            default:
                output.append(.nature)
            }
        }

        return output
    }

    static func areManifestPresent(url: URL) -> Bool {
        // For a source to be valid we at the very least need two things
        // manifest.json    <- a description of the source
        // entries.json     <- the classic video manifest
        return FileManager.default.fileExists(atPath: url.path.appending("/entries.json")) ||
           FileManager.default.fileExists(atPath: url.path.appending("/manifest.json"))
    }

}

// MARK: - MetaManifest
struct MetaManifest: Codable {
    let sources: [Manifest]
}

// MARK: - Manifest
struct Manifest: Codable {
    let name, manifestDescription: String
    let scenes: [String]?
    let local: Bool?
    let cacheable: Bool?
    let manifestUrl: String?

    enum CodingKeys: String, CodingKey {
        case name
        case manifestDescription = "description"
        case scenes
        case local
        case cacheable
        case manifestUrl
    }
}
