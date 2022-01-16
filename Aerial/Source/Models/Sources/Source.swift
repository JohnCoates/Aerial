//
//  Source.swift
//  Aerial
//
//  Created by Guillaume Louel on 01/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Foundation

// 10 has a different format
// 11 is similar to 12+, but does not include pointsOfInterests
// 12/13 share a same format, and we use that format for local videos too
enum SourceType: Int, Codable {
    case local, tvOS10, tvOS11, tvOS12
}

enum SourceScene: String, Codable {
    case nature = "Nature", city = "City", space = "Space", sea = "Sea", beach = "Beach", countryside = "Countryside"
}

// swiftlint:disable:next type_body_length
struct Source: Codable {
    var name: String
    var description: String
    var manifestUrl: String
    var type: SourceType
    var scenes: [SourceScene]
    var isCachable: Bool
    var license: String
    var more: String

    // TODO
    func isEnabled() -> Bool {
        // tvOS is always enabled
        /*if name.starts(with: "tvOS") {
            return true
        }*/

        if PrefsVideos.enabledSources.keys.contains(name) {
            return PrefsVideos.enabledSources[name]!
        }

        // Unknown sources are enabled
        return true
    }

    func diskUsage() -> Double {
        let path = Cache.supportPath.appending("/" + name)

        return Cache.getDirectorySize(directory: path)
    }

    func wipeFromDisk() {
        let path = Cache.supportPath.appending("/" + name)

        if FileManager.default.fileExists(atPath: path) {
            try? FileManager.default.removeItem(atPath: path)
        }
    }

    func setEnabled(_ enabled: Bool) {
        PrefsVideos.enabledSources[name] = enabled
        VideoList.instance.reloadSources()
    }

    // Is the source already cached or not ?
    func isCached() -> Bool {
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: Cache.supportPath.appending("/" + name + "/entries.json"))
    }

    func lastUpdated() -> String {
        if isCached() {
            var date: Date?
            if !isCachable && type == .local {
                date = (try? FileManager.default.attributesOfItem(atPath:
                Cache.supportPath.appending("/" + name + "/entries.json")))?[.modificationDate] as? Date
            } else {
                date = (try? FileManager.default.attributesOfItem(atPath:
                Cache.supportPath.appending("/" + name + "/entries.json")))?[.creationDate] as? Date
            }

            if date != nil {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                return dateFormatter.string(from: date!)
            } else {
                return ""
            }
        }
        return ""
    }

    func getUnprocessedVideos() -> [AerialVideo] {
        if isCached() {
            do {
                let cacheFileUrl = URL(fileURLWithPath: Cache.supportPath.appending("/" + name + "/entries.json"))
                let jsondata = try Data(contentsOf: cacheFileUrl)

                return readVideoManifest(jsondata)
            } catch {
                errorLog("\(name) could not be opened")
                return []
            }
        } else {
            debugLog("\(name) is not cached")
            return []
        }
    }

    func getVideos() -> [AerialVideo] {
        if isCached() {
            do {
                let cacheFileUrl = URL(fileURLWithPath: Cache.supportPath.appending("/" + name + "/entries.json"))
                let jsondata = try Data(contentsOf: cacheFileUrl)

                if name == "tvOS 10" {
                    return parseOldVideoManifest(jsondata)
                } else if name.starts(with: "tvOS 13") {
                    return parseVideoManifest(jsondata) + getMissingVideos()  // Oh, Victoria Harbour 2...
                } else {
                    return parseVideoManifest(jsondata)
                }
            } catch {
                errorLog("\(name) could not be opened")
                return []
            }
        } else {
            debugLog("\(name) is not cached")
            return []
        }
    }

    func localizePath(_ path: String?) -> String {
        if let tpath = path {
            if manifestUrl.starts(with: "file://") {
                return manifestUrl + tpath
            }

            return tpath
        } else {
            return ""
        }
    }

    // The things we do for one single missing video (for now) ;)
    func getMissingVideos() -> [AerialVideo] {
        // We also need to add the missing videos
        let bundlePath = Bundle(for: PanelWindowController.self).path(forResource: "missingvideos", ofType: "json")!
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: bundlePath), options: .mappedIfSafe)
            return parseVideoManifest(data)
        } catch {
            errorLog("missingvideos.json was not found in the bundle")
        }

        return []
    }

    // MARK: - JSON processing
    func readOldJSONFromData(_ data: Data) -> [AerialVideo] {
        var processedVideos: [AerialVideo] = []

        do {
            let poiStringProvider = PoiStringProvider.sharedInstance

            let options = JSONSerialization.ReadingOptions.allowFragments
            let batches = try JSONSerialization.jsonObject(with: data,
                                                           options: options) as! [NSDictionary]

            for batch: NSDictionary in batches {
                let assets = batch["assets"] as! [NSDictionary]
                // rawCount = assets.count

                for item in assets {
                    let url = item["url"] as! String
                    let name = item["accessibilityLabel"] as! String
                    let timeOfDay = item["timeOfDay"] as! String
                    let id = item["id"] as! String
                    let type = item["type"] as! String

                    if type != "video" {
                        continue
                    }

                    // We may have a secondary name
                    var secondaryName = ""
                    if let mergename = poiStringProvider.getCommunityName(id: id) {
                        secondaryName = mergename
                    }

                    // We may have POIs to merge
                    /*var poi: [String: String]?
                    if let mergeId = SourceInfo.mergePOI[id] {
                        let poiStringProvider = PoiStringProvider.sharedInstance
                        poi = poiStringProvider.fetchExtraPoiForId(id: mergeId)
                    }*/

                    let communityPoi = poiStringProvider.getCommunityPoi(id: id)

                    // We may have dupes...
                    let (isDupe, foundDupe) = SourceInfo.findDuplicate(id: id, url1080pH264: url)
                    if isDupe {
                        if foundDupe != nil {
                            // foundDupe!.sources.append(manifest)

                            if foundDupe?.urls[.v1080pH264] == "" {
                                foundDupe?.urls[.v1080pH264] = url
                            }
                        }
                    } else {
                        var url1080pHEVC = ""
                        var url1080pHDR = ""
                        var url4KHEVC = ""
                        var url4KHDR = ""

                        // Check if we have some HEVC urls to merge
                        if let val = SourceInfo.mergeInfo[id] {
                            url1080pHEVC = val["url-1080-SDR"]!
                            url1080pHDR = val["url-1080-HDR"]!
                            url4KHEVC = val["url-4K-SDR"]!
                            url4KHDR = val["url-4K-HDR"]!
                        }

                        let urls: [VideoFormat: String] = [.v1080pH264: url,
                                                           .v1080pHEVC: url1080pHEVC,
                                                           .v1080pHDR: url1080pHDR,
                                                           .v4KHEVC: url4KHEVC,
                                                           .v4KHDR: url4KHDR ]

                        // Now we can finally add...
                        let video = AerialVideo(id: id,             // Must have
                            name: name,         // Must have
                            secondaryName: secondaryName,
                            type: type,         // Not sure the point of this one ?
                            timeOfDay: timeOfDay,
                            scene: "landscape",
                            urls: urls,
                            source: self,
                            poi: [:],
                            communityPoi: communityPoi)

                        processedVideos.append(video)
                    }
                }
            }

            return processedVideos
        } catch {
            errorLog("Error retrieving content listing (old)")
            return []
        }
    }

    func getSecondaryNameFor(_ asset: VideoAsset) -> String {
        let poiStringProvider = PoiStringProvider.sharedInstance

        if let mergename = poiStringProvider.getCommunityName(id: asset.id) {
            return mergename
        } else {
            return asset.title ?? ""
        }
    }

    func getSceneFor(_ asset: VideoAsset) -> String {
        if let updatedScene = SourceInfo.getSceneForVideo(id: asset.id) {
            return updatedScene.rawValue.lowercased()
        } else {
            return asset.scene ?? "landscape"
        }
    }

    func urlsFor(_ asset: VideoAsset) -> [VideoFormat: String] {
        return [.v1080pH264: localizePath(asset.url1080H264),
                .v1080pHEVC: localizePath(asset.url1080SDR),
                .v1080pHDR: localizePath(asset.url1080HDR),
                .v4KHEVC: localizePath(asset.url4KSDR),
                .v4KHDR: localizePath(asset.url4KHDR) ]
    }

    func oldUrlsFor(_ asset: VideoAsset) -> [VideoFormat: String] {
        var url1080pHEVC = ""
        var url1080pHDR = ""
        var url4KHEVC = ""
        var url4KHDR = ""

        // Check if we have some HEVC urls to merge
        if let val = SourceInfo.mergeInfo[asset.id] {
            url1080pHEVC = val["url-1080-SDR"]!
            url1080pHDR = val["url-1080-HDR"]!
            url4KHEVC = val["url-4K-SDR"]!
            url4KHDR = val["url-4K-HDR"]!
        }

        return [.v1080pH264: asset.url ?? "",
                .v1080pHEVC: url1080pHEVC,
                .v1080pHDR: url1080pHDR,
                .v4KHEVC: url4KHEVC,
                .v4KHDR: url4KHDR ]
    }

    func parseOldVideoManifest(_ data: Data) -> [AerialVideo] {
        do {
            let oldVideoManifest = try newJSONDecoder().decode(OldVideoManifest.self, from: data)
            var processedVideos: [AerialVideo] = []

            for group in oldVideoManifest {
                for asset in group.assets {
                    let (isDupe, foundDupe) = SourceInfo.findDuplicate(id: asset.id, url1080pH264: asset.url ?? "")

                    if isDupe {
                        if let dupe = foundDupe {
                            if dupe.urls[.v1080pH264] == "" {
                                dupe.urls[.v1080pH264] = asset.url
                            }
                        }
                    } else {
                        var poi: [String: String]?
                        if let mergeId = SourceInfo.mergePOI[asset.id] {
                            let poiStringProvider = PoiStringProvider.sharedInstance
                            poi = poiStringProvider.fetchExtraPoiForId(id: mergeId)
                        }

                        let video = AerialVideo(id: asset.id,
                            name: asset.accessibilityLabel,
                            secondaryName: getSecondaryNameFor(asset),
                            type: "video",
                            timeOfDay: asset.timeOfDay ?? "day",
                            scene: getSceneFor(asset),
                            urls: oldUrlsFor(asset),
                            source: self,
                            poi: poi ?? [:],
                            communityPoi: PoiStringProvider.sharedInstance.getCommunityPoi(id: asset.id))

                        processedVideos.append(video)
                    }
                }
            }

            return processedVideos
        } catch let error {
            debugLog(error.localizedDescription)
            errorLog("### Could not parse manifest data")
            return []
        }
    }

    func readVideoManifest(_ data: Data) -> [AerialVideo] {
        if let videoManifest = try? newJSONDecoder().decode(VideoManifest.self, from: data) {
            var processedVideos: [AerialVideo] = []

            for asset in videoManifest.assets {
                let video = AerialVideo(id: asset.id,
                    name: asset.accessibilityLabel,
                    secondaryName: getSecondaryNameFor(asset),
                    type: "video",
                    timeOfDay: asset.timeOfDay ?? "day",
                    scene: getSceneFor(asset),
                    urls: urlsFor(asset),
                    source: self,
                    poi: asset.pointsOfInterest ?? [:],
                    communityPoi: PoiStringProvider.sharedInstance.getCommunityPoi(id: asset.id))

                processedVideos.append(video)
            }

            return processedVideos
        }

        errorLog("### Could not parse manifest data")
        return []
    }

    func parseVideoManifest(_ data: Data) -> [AerialVideo] {
        if let videoManifest = try? newJSONDecoder().decode(VideoManifest.self, from: data) {
            // Let's save the manifest here
            // manifest = videoManifest

            var processedVideos: [AerialVideo] = []

            for asset in videoManifest.assets {
                let (isDupe, _) = SourceInfo.findDuplicate(id: asset.id, url1080pH264: asset.url1080H264 ?? "")

                if !isDupe {
                    let video = AerialVideo(id: asset.id,
                        name: asset.accessibilityLabel,
                        secondaryName: getSecondaryNameFor(asset),
                        type: "video",
                        timeOfDay: asset.timeOfDay ?? "day",
                        scene: getSceneFor(asset),
                        urls: urlsFor(asset),
                        source: self,
                        poi: asset.pointsOfInterest ?? [:],
                        communityPoi: PoiStringProvider.sharedInstance.getCommunityPoi(id: asset.id))

                    processedVideos.append(video)
                }
            }

            return processedVideos
        }

        errorLog("### Could not parse manifest data")
        return []
    }
}

// MARK: - VideoManifest
/// The newer format used by all our other JSONs
struct VideoManifest: Codable {
    let assets: [VideoAsset]
    let initialAssetCount, version: Int?
}

// MARK: - OldVideoManifestElement
/// This is tvOS 10's manifest format
struct OldVideoManifestElement: Codable {
    let id: String
    let assets: [VideoAsset]
}

typealias OldVideoManifest = [OldVideoManifestElement]

// MARK: - VideoAsset
/// Common Asset structure for all our JSONs
///
/// I've added multiple extra fields that aren't in Apple's JSONs, including:
/// - title: as in Los Angeles (accesibilityLabel) / Santa Monica Beach (title)
/// - timeOfDay: only on tvOS 10, resurected for custom sources, can also be sunset or sunrise
/// - scene: landscape, city, space, sea
struct VideoAsset: Codable {
    let accessibilityLabel, id: String
    let title: String?
    let timeOfDay: String?
    let scene: String?
    let pointsOfInterest: [String: String]?
    let url4KHDR, url4KSDR, url1080H264, url1080HDR: String?
    let url1080SDR, url: String?
    let type: String?

    enum CodingKeys: String, CodingKey {
        case accessibilityLabel, id, pointsOfInterest
        case title, timeOfDay, scene
        case url4KHDR = "url-4K-HDR"
        case url4KSDR = "url-4K-SDR"
        case url1080H264 = "url-1080-H264"
        case url1080HDR = "url-1080-HDR"
        case url1080SDR = "url-1080-SDR"
        case url
        case type
    }
}
