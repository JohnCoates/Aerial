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
// 12/13 share a same format, and we use that format for custom too
enum SourceType: Int, Codable {
    case custom, tvOS10, tvOS11, tvOS12
}

struct Source: Codable {
    var name: String
    var description: String
    var manifestUrl: String
    var type: SourceType

    // TODO
    func isEnabled() -> Bool {
        //return name == "tvOS 11"
        return true
    }

    // Is the source already cached or not ?
    func isCached() -> Bool {
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: Cache.supportPath.appending("/" + name + "/entries.json"))
    }

    func getVideos() -> [AerialVideo] {
        if isCached() {
            do {
                let cacheFileUrl = URL(fileURLWithPath: Cache.supportPath.appending("/" + name + "/entries.json"))
                let jsondata = try Data(contentsOf: cacheFileUrl)

                if name == "tvOS 10" {
                    return readOldJSONFromData(jsondata)
                } else {
                    return readJSONFromData(jsondata)
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

    // MARK: - JSON processing
    func readJSONFromData(_ data: Data) -> [AerialVideo] {
        var processedVideos: [AerialVideo] = []

        do {
            let poiStringProvider = PoiStringProvider.sharedInstance

            let options = JSONSerialization.ReadingOptions.allowFragments
            let batches = try JSONSerialization.jsonObject(with: data, options: options)

            guard let batch = batches as? NSDictionary else {
                errorLog("Encountered unexpected content type for batch, please report !")
                return []
            }

            let assets = batch["assets"] as! [NSDictionary]

            for item in assets {
                let id = item["id"] as! String
                let url1080pH264 = item["url-1080-H264"] as? String
                let url1080pHEVC = item["url-1080-SDR"] as? String
                let url1080pHDR = item["url-1080-HDR"] as? String
                let url4KHEVC = item["url-4K-SDR"] as? String
                let url4KHDR = item["url-4K-HDR"] as? String
                let name = item["accessibilityLabel"] as! String

                let urls: [VideoFormat: String] = [.v1080pH264: url1080pH264 ?? "",
                                                   .v1080pHEVC: url1080pHEVC ?? "",
                                                   .v1080pHDR: url1080pHDR ?? "",
                                                   .v4KHEVC: url4KHEVC ?? "",
                                                   .v4KHDR: url4KHDR ?? "", ]
                var secondaryName = ""
                // We may have a secondary name
                if let mergename = poiStringProvider.getCommunityName(id: id) {
                    secondaryName = mergename
                }

                let timeOfDay = "day"   // TODO, this is hardcoded as it's no longer available in the modern JSONs
                let type = "video"
                var poi: [String: String]?

                poi = item["pointsOfInterest"] as? [String: String]

                let communityPoi = poiStringProvider.getCommunityPoi(id: id)

                let (isDupe, foundDupe) = SourceInfo.findDuplicate(id: id, url1080pH264: url1080pH264 ?? "")
                if isDupe {
                    // foundDupe!.sources.append(manifest)
                } else {
                    let video = AerialVideo(id: id,             // Must have
                        name: name,                             // Must have
                        secondaryName: secondaryName,           // Optional
                        type: type,                             // Not sure the point of this one ?
                        timeOfDay: timeOfDay,
                        urls: urls,
                        manifest: .tvOS13,
                        poi: poi ?? [:],
                        communityPoi: communityPoi)

                    processedVideos.append(video)
                }
            }

            //
            return processedVideos
        } catch {
            errorLog("Error retrieving content listing (new)")
            return []
        }
    }

    func readOldJSONFromData(_ data: Data) -> [AerialVideo] {
        var processedVideos: [AerialVideo] = []

        do {
            let poiStringProvider = PoiStringProvider.sharedInstance

            let options = JSONSerialization.ReadingOptions.allowFragments
            let batches = try JSONSerialization.jsonObject(with: data,
                                                           options: options) as! [NSDictionary]

            for batch: NSDictionary in batches {
                let assets = batch["assets"] as! [NSDictionary]

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
                    if let mergeId = mergePOI[id] {
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
                                                           .v4KHDR: url4KHDR, ]

                        // Now we can finally add...
                        let video = AerialVideo(id: id,             // Must have
                            name: name,         // Must have
                            secondaryName: secondaryName,
                            type: type,         // Not sure the point of this one ?
                            timeOfDay: timeOfDay,
                            urls: urls,
                            manifest: .tvOS10,
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
}
