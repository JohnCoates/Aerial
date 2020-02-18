//
//  AerialVideo.swift
//  Aerial
//
//  Created by John Coates on 10/23/15.
//  Copyright © 2015 John Coates. All rights reserved.
//

import Foundation
import AVFoundation

enum Manifests: String {
    // swiftlint:disable:next line_length
    case tvOS10 = "tvos10.json", tvOS11 = "tvos11.json", tvOS12 = "tvos12.json", tvOS13 = "tvos13.json", tvOS13Strings = "TVIdleScreenStrings13.bundle", customVideos = "customvideos.json"
}

private let spaceVideos = [
    "A837FA8C-C643-4705-AE92-074EFDD067F7",
    "2F72BC1E-3D76-456C-81EB-842EBA488C27",
    "A2BE2E4A-AD4B-428A-9C41-BDAE1E78E816",
    "12318CCB-3F78-43B7-A854-EFDCCE5312CD",
    "D5CFB2FF-5F8C-4637-816B-3E42FC1229B8",
    "4F881F8B-A7D9-4FDB-A917-17BF6AC5A589",
    "6A74D52E-2447-4B84-AE45-0DEF2836C3CC",
    "7825C73A-658F-48EE-B14C-EC56673094AC",
    "E5DB138A-F04E-4619-B896-DE5CB538C534",
    "F439B0A7-D18C-4B14-9681-6520E6A74FE9",
    "62A926BE-AA0B-4A34-9653-78C4F130543F",
    "7C643A39-C0B2-4BA0-8BC2-2EAA47CC580E",
    "6C3D54AE-0871-498A-81D0-56ED24E5FE9F",
    "009BA758-7060-4479-8EE8-FB9B40C8FB97",
    "78911B7E-3C69-47AD-B635-9C2486F6301D",
    "D60B4DDA-69EB-4841-9690-E8BAE7BC4F80",
    "7719B48A-2005-4011-9280-2F64EEC6FD91",
    "63C042F0-90EF-4A95-B7CC-CC9A64BF8421",
    "B1B5DDC5-73C8-4920-8133-BACCE38A08DE",
    "03EC0F5E-CCA8-4E0A-9FEC-5BD1CE151182",             // 25/01 Antartica Aurora
    "737E9E24-49BE-4104-9B72-F352DE1AD2BF",             // North America Aurora
    "E556BBC5-D0A0-4DB1-AC77-BC76E4A526F4",             // Sahara and Italy
    "64D11DAB-3B57-4F14-AD2F-E59A9282FA44",             // Atlantic Ocean to Spain and France
    "81337355-E156-4242-AAF4-711768D30A54",             // Australia
    "1088217C-1410-4CF7-BDE9-8F573A4DBCD9",             // Caribbean
    "3C4678E4-4D3D-4A40-8817-77752AEA62EB",             // Nile Delta
    "87060EC2-D006-4102-98CC-3005C68BB343",             // South Africa to North Asia

]

private let seaVideos = [
    "83C65C90-270C-4490-9C69-F51FE03D7F06", // Seals (outdated)
    "BA4ECA11-592F-4727-9221-D2A32A16EB28", // Palau Jellies *
    "F07CC61B-30FC-4614-BDAD-3240B61F6793", // Palau Coral
    "6143116D-03BB-485E-864E-A8CF58ACF6F1", // Kelp
    "2B30E324-E4FF-4CC1-BA45-A958C2D2B2EC", // Barracuda
    "E580E5A5-0888-4BE8-A4CA-F74A18A643C3", // Palau Jellies *
    "EC3DC957-D4C2-4732-AACE-7D0C0F390EC8", // Palau Jellies *
    "581A4F1A-2B6D-468C-A1BE-6F473F06D10B", // Sea Stars
    "687D03A2-18A5-4181-8E85-38F3A13409B9", // Bumpheads
    "537A4DAB-83B0-4B66-BCD1-05E5DBB4A268", // Jacks
    "C7AD3D0A-7EDF-412C-A237-B3C9D27381A1", // Alaskan Jellies *
    "C6DC4E54-1130-44F8-AF6F-A551D8E8A181", // Alaskan Jellies *
    "27A37B0F-738D-4644-A7A4-E33E7A6C1175", // California Dolphins
    "EB3F48E7-D30F-4079-858F-1A61331D5026", // California Kelp Forest
    "CE9B5D5B-B6E7-47C5-8C04-59BF182E98FB", // Costa Rica Dolphins
    "58C75C62-3290-47B8-849C-56A583173570", // Cownose Rays
    "3716DD4B-01C0-4F5B-8DD6-DB771EC472FB", // Gray Reef Sharks
    "DD47D8E1-CB66-4C12-BFEA-2ADB0D8D1E2E", // Humpback Whale
    "82175C1F-153C-4EC8-AE37-2860EA828004", // Red Sea Coral
    "149E7795-DBDA-4F5D-B39A-14712F841118", // Tahiti Waves *
    "8C31B06F-91A4-4F7C-93ED-56146D7F48B9", // Tahiti Waves *
    "391BDF6E-3279-4CE1-9CA5-0F82811452D7", // Seals (new version)
]

private let timeInformation = [
    "A837FA8C-C643-4705-AE92-074EFDD067F7": "night",    // Africa Night
    "2F72BC1E-3D76-456C-81EB-842EBA488C27": "day",      // Africa and the Middle East
    "A2BE2E4A-AD4B-428A-9C41-BDAE1E78E816": "night",    // California to Vegas (v7)
    "12318CCB-3F78-43B7-A854-EFDCCE5312CD": "night",    // California to Vegas (v8)
    "D5CFB2FF-5F8C-4637-816B-3E42FC1229B8": "day",      // Carribean
    "4F881F8B-A7D9-4FDB-A917-17BF6AC5A589": "day",      // Carribean day
    "6A74D52E-2447-4B84-AE45-0DEF2836C3CC": "night",    // China
    "7825C73A-658F-48EE-B14C-EC56673094AC": "night",    // China (new id)
    "E5DB138A-F04E-4619-B896-DE5CB538C534": "night",    // Italy to Asia
    "F439B0A7-D18C-4B14-9681-6520E6A74FE9": "night",    // Iran and Afghanistan
    "62A926BE-AA0B-4A34-9653-78C4F130543F": "night",    // Ireland to Asia
    "7C643A39-C0B2-4BA0-8BC2-2EAA47CC580E": "night",    // Ireland to Asia
    "6C3D54AE-0871-498A-81D0-56ED24E5FE9F": "night",    // Korean and Japan Night (v17)
    "009BA758-7060-4479-8EE8-FB9B40C8FB97": "night",    // Korean and Japan Night (v18)
    "78911B7E-3C69-47AD-B635-9C2486F6301D": "day",      // New Zealand (sunrise...)
    "D60B4DDA-69EB-4841-9690-E8BAE7BC4F80": "day",      // Sahara and Italy
    "E556BBC5-D0A0-4DB1-AC77-BC76E4A526F4": "day",      // Sahara and Italy
    "7719B48A-2005-4011-9280-2F64EEC6FD91": "day",      // Southern California to Baja
    "63C042F0-90EF-4A95-B7CC-CC9A64BF8421": "day",      // Western Africa to the Alps (sunset...)
    "BAF76353-3475-4855-B7E1-CE96CC9BC3A7": "night",    // Dubai
    "30313BC1-BF20-45EB-A7B1-5A6FFDBD2488": "night",    // Hong Kong
    "89B1643B-06DD-4DEC-B1B0-774493B0F7B7": "night",    // Los Angeles
    "EC67726A-8212-4C5E-83CF-8412932740D2": "night",    // Los Angeles
    "A284F0BF-E690-4C13-92E2-4672D93E8DE5": "night",    // Los Angeles
    "B1B5DDC5-73C8-4920-8133-BACCE38A08DE": "night",    // New York night
    "9680B8EB-CE2A-4395-AF41-402801F4D6A6": "night",    // Approaching Burj Khalifa
    "EE01F02D-1413-436C-AB05-410F224A5B7B": "night",    // Ilulissat Icefjord
    "E99FA658-A59A-4A2D-9F3B-58E7BDC71A9A": "night",    // Hong Kong Victoria Harbour
    "3E94AE98-EAF2-4B09-96E3-452F46BC114E": "night",    // Bay Bridge
    "29BDF297-EB43-403A-8719-A78DA11A2948": "night",    // Fisherman's Wharf
    "82BD33C9-B6D2-47E7-9C42-AA3B7758921A": "night",    // Pu'u O 'Umi Night
    "3D729CFC-9000-48D3-A052-C5BD5B7A6842": "night",    // Kohala Coastline
    "F604AF56-EA77-4960-AEF7-82533CC1A8B3": "night",    // River Thames near sunset
    "7F4C26C2-67C2-4C3A-8F07-8A7BF6148C97": "night",    // River Thames at dusk
    "F5804DD6-5963-40DA-9FA0-39C0C6E6DEF9": "night",    // Downtown (LA)
    "640DFB00-FBB9-45DA-9444-9F663859F4BC": "night",    // Lower Manhattan
    "44166C39-8566-4ECA-BD16-43159429B52F": "night",    // Seventh Avenue
    "03EC0F5E-CCA8-4E0A-9FEC-5BD1CE151182": "night",    // Antartica Aurora
    "737E9E24-49BE-4104-9B72-F352DE1AD2BF": "night",    // North America Aurora
]

final class AerialVideo: CustomStringConvertible, Equatable {
    static func ==(lhs: AerialVideo, rhs: AerialVideo) -> Bool {
        return lhs.id == rhs.id // TODO && lhs.url1080pHEVC == rhs.url1080pHEVC
    }

    let id: String
    let name: String
    let secondaryName: String
    let type: String
    let timeOfDay: String

    var urls: [VideoFormat: String]

    var sources: [Manifests]
    let poi: [String: String]
    let communityPoi: [String: String]
    var duration: Double

    var arrayPosition = 1
    var contentLength = 0
    var contentLengthChecked = false

    var isAvailableOffline: Bool {
        return VideoCache.isAvailableOffline(video: self)
    }

    // MARK: - Public getter
    var url: URL {
        return getClosestAvailable(wanted: PrefsVideos.videoFormat)
    }

    // Returns the closest video we have in the manifests
    private func getClosestAvailable(wanted: VideoFormat) -> URL {
        if urls[wanted] != "" {
            return URL(string: urls[wanted]!)!
        } else {
            // Fallback
            if urls[.v4KHEVC] != "" {
                return URL(string: urls[.v4KHEVC]!)!

            } else if urls[.v1080pHEVC] != "" {
                return URL(string: urls[.v1080pHEVC]!)!
            } else { // Last resort
                return URL(string: urls[.v1080pH264]!)!
            }
        }
    }

    // MARK: - Init
    init(id: String,
         name: String,
         secondaryName: String,
         type: String,
         timeOfDay: String,
         urls: [VideoFormat: String],
         manifest: Manifests,
         poi: [String: String],
         communityPoi: [String: String]
    ) {
        self.id = id

        // We override names for known space videos
        if seaVideos.contains(id) {
            self.name = "Sea"
            if secondaryName != "" {
                self.secondaryName = secondaryName
            } else {
                self.secondaryName = name
            }
        } else if spaceVideos.contains(id) {
            self.name = "Space"
            if secondaryName != "" {
                self.secondaryName = secondaryName
            } else {
                self.secondaryName = name
            }
        } else {
            // We align to the new jsons...
            if name == "New York City" {
                self.name = "New York"
            } else {
                self.name = name
            }
            self.secondaryName = secondaryName      // We may have a secondary name from our merges too now !
        }

        self.type = type

        // We override timeOfDay based on our own list
        if let val = timeInformation[id] {
            self.timeOfDay = val
        } else {
            self.timeOfDay = timeOfDay
        }

        self.urls = urls
        self.sources = [manifest]
        self.poi = poi
        self.communityPoi = communityPoi
        self.duration = 0

        updateDuration()    // We need to have the video duration
    }

    func updateDuration() {
        // We need to retrieve video duration from the cached files.
        // This is a workaround as currently, the VideoCache infrastructure
        // relies on AVAsset with an external URL all the time, even when
        // working on a cached copy which makes the native duration retrieval fail

        let fileManager = FileManager.default

        // With custom videos, we may already store the local path
        // If so, check it
        if self.url.absoluteString.starts(with: "file") {
            if fileManager.fileExists(atPath: self.url.path) {
                let asset = AVAsset(url: self.url)
                self.duration = CMTimeGetSeconds(asset.duration)
            } else {
                errorLog("Custom video is missing : \(self.url.path)")
                self.duration = 0
            }
        } else {
            // If not, iterate through all possible versions to see if any is cached
            for format in VideoFormat.allCases {
                // swiftlint:disable:next for_where
                if urls[format] != "" {
                    let path = VideoCache.cachePath(forFilename: (URL(string: urls[format]!)!.lastPathComponent))!

                    if fileManager.fileExists(atPath: path) {
                        let asset = AVAsset(url: URL(fileURLWithPath: path))
                        self.duration = CMTimeGetSeconds(asset.duration)
                        //print("duration found \(self.duration)")
                        return
                    }
                }
            }

            // print("no duration for \(self)")
        }
    }

    func has4KVersion() -> Bool {
        return urls[.v4KHEVC] != ""
    }

    var description: String {
        return """
        id=\(id),
        name=\(name),
        type=\(type),
        timeofDay=\(timeOfDay),
        urls=\(urls)
        """
    }
}
