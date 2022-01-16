//
//  SourceList.swift
//  Aerial
//
//  Created by Guillaume Louel on 01/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Foundation

struct SourceHeader {
    let name: String
    let sources: [Source]
}

// swiftlint:disable:next type_body_length
struct SourceList {
    // This is the current one until next fall
    static let tvOS15 = Source(name: "tvOS 15",
                        description: "Apple TV screensavers from tvOS 15",
                        manifestUrl: "https://sylvan.apple.com/Aerials/resources-15.tar",
                        type: .tvOS12,
                        scenes: [.nature, .city, .space, .sea],
                        isCachable: true,
                        license: "",
                        more: "")

    // Legacy sources
    static let tvOS13 = Source(name: "tvOS 13",
                        description: "Apple TV screensavers from tvOS 13",
                        manifestUrl: "https://sylvan.apple.com/Aerials/resources-13.tar",
                        type: .tvOS12,
                        scenes: [.nature, .city, .space, .sea],
                        isCachable: true,
                        license: "",
                        more: "")

    static let tvOS12 = Source(name: "tvOS 12",
                        description: "Apple TV screensavers from tvOS 12",
                        manifestUrl: "https://sylvan.apple.com/Aerials/resources.tar",
                        type: .tvOS12,
                        scenes: [.nature, .city, .space],
                        isCachable: true,
                        license: "",
                        more: "")

    static let tvOS11 = Source(name: "tvOS 11",
                        description: "Apple TV screensavers from tvOS 11",
                        manifestUrl: "https://sylvan.apple.com/Aerials/2x/entries.json",
                        type: .tvOS11,
                        scenes: [.nature, .city],
                        isCachable: true,
                        license: "",
                        more: "")

    static let tvOS10 = Source(name: "tvOS 10",
                        description: "Apple TV screensavers from tvOS 10",
                        manifestUrl: "http://a1.phobos.apple.com/us/r1000/000/Features/atv/AutumnResources/videos/entries.json",
                        type: .tvOS10,
                        scenes: [.nature, .city],
                        isCachable: true,
                        license: "",
                        more: "")

    static var list: [Source] = [tvOS15, tvOS13, tvOS10] + foundSources
    // static var list: [Source] = foundSources

    // This is where the magic happens
    static var foundSources: [Source] {
        var sources: [Source] = []
        var foundCommunity = false

        for folder in URL(fileURLWithPath: Cache.supportPath).subDirectories {
            if !folder.lastPathComponent.starts(with: "tvOS")
                && !folder.lastPathComponent.starts(with: "backups")
                && !folder.lastPathComponent.starts(with: "Thumbnails")
                && !folder.lastPathComponent.starts(with: "Cache") {

                if folder.lastPathComponent.starts(with: "Community") || folder.lastPathComponent.starts(with: "From") {
                    foundCommunity = true
                }

                // If it's valid, let's add !
                if let source = loadManifest(url: folder) {
                    sources.append(source)
                } else if let newsources = loadMetaManifest(url: folder) {
                    sources.append(contentsOf: newsources)
                }
            }
        }

        if !foundCommunity {
            DispatchQueue.main.async {
                fetchOnlineManifest(url: URL(string: "https://aerialscreensaver.github.io/community/")!)
            }
        }

        return sources
    }

    // swiftlint:disable for_where
    static func hasNamed(name: String) -> Bool {
        for source in list where source.type == .local {
            if source.name == name {
                return true
            }
        }

        return false
    }

    static func categorizedSourceList() -> [SourceHeader] {
        var communities: [Source] = []
        var online: [Source] = []
        var local: [Source] = []
        var apple: [Source] = []

        for source in list { // where !source.name.starts(with: "tvOS") {
            if source.type == .local {
                local.append(source)
            } else {
                // This may need to be changed in the future
                if !source.isCachable {
                    online.append(source)
                } else if source.name.starts(with: "tvOS") {
                    apple.append(source)
                } else {
                    communities.append(source)
                }
            }
        }

        // Then we build our list
        var output: [SourceHeader] = []

        if !communities.isEmpty {
            output.append(SourceHeader(name: "Community Videos", sources: communities))
        }

        if !online.isEmpty {
            output.append(SourceHeader(name: "Online Sources", sources: online))
        }

        if !apple.isEmpty {
            output.append(SourceHeader(name: "Apple TV", sources: apple))
        }

        if !local.isEmpty {
            output.append(SourceHeader(name: "Local Sources", sources: local))
        }

        return output
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
            debugLog("Something went wrong here")
            let task = URLSession.shared.dataTask(with: url) { _, response, error in

                if let error = error {
                    debugLog("Can't load file, possible firewall issue")
                    DispatchQueue.main.async {
                        Aerial.showErrorAlert(question: "An error occured loading the file",
                            text: "Please check your network connection, firewall, and try again. \n\nError : \(error.localizedDescription)")
                    }
                    return
                }
                guard let response = response as? HTTPURLResponse else {
                    debugLog("No HTTP response")

                    DispatchQueue.main.async {
                        Aerial.showErrorAlert(question: "No HTTP Response",
                                              text: "Please check your network connection, firewall, and try again.")
                    }
                    return
                }

                if response.statusCode != 200 {
                    DispatchQueue.main.async {
                        debugLog("HTTP error")

                        Aerial.showErrorAlert(question: "HTTP Error",
                            text: "Please verify the URL (and check your network connexion and firewall). HTTP error: \(response.statusCode)")
                    }
                    return
                } else {
                    DispatchQueue.main.async {
                        debugLog("Incorect JSON format")

                        Aerial.showErrorAlert(question: "Incorrect JSON Format",
                                              text: "Your URL was valid, but the file is not in the correct format. Please check the URL.")
                    }
                    return
                }
            }
            task.resume()
        }
    }

    static func updateLocalSource(source: Source) {
        // We need the raw manifest to find the path inside
        let videos = source.getUnprocessedVideos()

        if videos.count >= 1 {
            let url = videos.first!.url.deletingLastPathComponent()
            let folderName = url.lastPathComponent
            debugLog("processing url for videos : \(url)")

            do {
                let urls = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
                var assets = [VideoAsset]()

                for lurl in urls {
                    if lurl.path.lowercased().hasSuffix(".mp4") || lurl.path.lowercased().hasSuffix(".mov") {
                        assets.append(VideoAsset(accessibilityLabel: folderName,
                                                 id: NSUUID().uuidString,
                                                 title: lurl.lastPathComponent,
                                                 timeOfDay: "day",
                                                 scene: "",
                                                 pointsOfInterest: [:],
                                                 url4KHDR: "",
                                                 url4KSDR: lurl.path,
                                                 url1080H264: "",
                                                 url1080HDR: "",
                                                 url1080SDR: "",
                                                 url: "",
                                                 type: "nature"))
                    }
                }

                debugLog("Updating manifest \(url.lastPathComponent)")

                let videoManifest = VideoManifest(assets: assets, initialAssetCount: 1, version: 1)

                SourceList.saveEntries(source: source, manifest: videoManifest)

                VideoList.instance.reloadSources()
            } catch {
                errorLog("Could not process directory")
            }
        } else {
            debugLog("Cannot parse your directory, did you delete your videos ?")
        }

    }

    static func processPathForVideos(url: URL) {
        debugLog("processing url for videos : \(url) ")
        let folderName = url.lastPathComponent

        do {
            let urls = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            var assets = [VideoAsset]()

            for lurl in urls {
                if lurl.path.lowercased().hasSuffix(".mp4") || lurl.path.lowercased().hasSuffix(".mov") {
                    assets.append(VideoAsset(accessibilityLabel: folderName,
                                             id: NSUUID().uuidString,
                                             title: lurl.lastPathComponent,
                                             timeOfDay: "day",
                                             scene: "",
                                             pointsOfInterest: [:],
                                             url4KHDR: "",
                                             url4KSDR: lurl.path,
                                             url1080H264: "",
                                             url1080HDR: "",
                                             url1080SDR: "",
                                             url: "",
                                             type: "nature"))
                }
            }

            // ...
            if SourceList.hasNamed(name: url.lastPathComponent) {
                Aerial.showInfoAlert(title: "Source name mismatch",
                                     text: "A source with this name already exists. Try renaming your folder and try again.")
            } else {
                debugLog("Creating source \(url.lastPathComponent)")

                // Generate and save the Source
                let source = Source(name: url.lastPathComponent,
                                    description: "Local files from \(url.path)",
                                    manifestUrl: "manifest.json",
                                    type: .local,
                                    scenes: [.nature],
                                    isCachable: false,
                                    license: "",
                                    more: "")

                SourceList.saveSource(source)

                // Then the entries
                let videoManifest = VideoManifest(assets: assets, initialAssetCount: 1, version: 1)

                SourceList.saveEntries(source: source, manifest: videoManifest)

                list.append(source)
                VideoList.instance.reloadSources()
            }
        } catch {
            errorLog("Could not process directory")
        }
    }

    static func saveSource(_ source: Source) {
        let manifest = Manifest.init(name: source.name,
                                     manifestDescription: source.description,
                                     scenes: source.scenes.map({ $0.rawValue }),
                                     local: source.type == .local,
                                     cacheable: source.isCachable,
                                     manifestUrl: source.manifestUrl,
                                     license: source.license,
                                     more: source.more)

        // First make the folder
        FileHelpers.createDirectory(atPath: Cache.supportPath.appending("/"+source.name))

        let json = try? JSONEncoder().encode(manifest)

        do {
            try json!.write(to: URL(fileURLWithPath:
                                    Cache.supportPath.appending("/"+source.name+"/manifest.json")))
        } catch {
            errorLog("Can't save local source : \(error.localizedDescription)")
        }
    }

    static func saveEntries(source: Source, manifest: VideoManifest) {
        let json = try? JSONEncoder().encode(manifest)

        do {
            try json!.write(to: URL(fileURLWithPath:
                                    Cache.supportPath.appending("/"+source.name+"/entries.json")))
        } catch {
            errorLog("Can't save local entries : \(error.localizedDescription)")
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
                debugLog("Manifest opened, going to parsing")
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

        debugLog("Parsed \(manifest.name)")

        return Source(name: manifest.name,
                      description: manifest.manifestDescription,
                      manifestUrl: mURL,
                      type: local ? .local : .tvOS12,
                      scenes: jsonToSceneArray(array: manifest.scenes ?? []),
                      isCachable: cacheable,
                      license: manifest.license ?? "",
                      more: manifest.more ?? "")
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
    let license: String?
    let more: String?

    enum CodingKeys: String, CodingKey {
        case name
        case manifestDescription = "description"
        case scenes
        case local
        case cacheable
        case manifestUrl
        case license
        case more
    }
}
