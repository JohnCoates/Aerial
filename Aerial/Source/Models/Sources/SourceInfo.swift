//
//  SourceInfo.swift
//  Aerial
//
//  Created by Guillaume Louel on 08/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Foundation

struct SourceInfo {
    // Those videos will be ignored
    static let blacklist = ["b10-1.mov",           // Dupe of b1-1 (Hawaii, day)
                     "b10-2.mov",           // Dupe of b2-3 (New York, night)
                     "b10-4.mov",           // Dupe of b2-4 (San Francisco, night)
                     "b9-1.mov",            // Dupe of b2-2 (Hawaii, day)
                     "b9-2.mov",            // Dupe of b3-1 (London, night)
                     "comp_LA_A005_C009_v05_t9_6M.mov",     // Low quality version of Los Angeles day 687B36CB-BA5D-4434-BA99-2F2B8B6EC163
                     "comp_LA_A009_C009_t9_6M_tag0.mov",
                     ]    // Low quality version of Los Angeles night 89B1643B-06DD-4DEC-B1B0-774493B0F7B7

    // This is used for videos where URLs should be merged with different ID
    // This is used to dedupe old versions of videos
    // old : new
    static let dupePairs = [
        "A2BE2E4A-AD4B-428A-9C41-BDAE1E78E816": "12318CCB-3F78-43B7-A854-EFDCCE5312CD",     // California to Vegas (v7 -> v8)
        "6A74D52E-2447-4B84-AE45-0DEF2836C3CC": "7825C73A-658F-48EE-B14C-EC56673094AC",     // China
        "6C3D54AE-0871-498A-81D0-56ED24E5FE9F": "009BA758-7060-4479-8EE8-FB9B40C8FB97",     // Korean and Japan night
        "b5-1": "044AD56C-A107-41B2-90CC-E60CCACFBCF5",                                     // Great Wall 3
        "b2-1": "22162A9B-DB90-4517-867C-C676BC3E8E95",                                     // Great wall 2
        "b6-1": "F0236EC5-EE72-4058-A6CE-1F7D2E8253BF",                                     // Great wall 1
        "BAF76353-3475-4855-B7E1-CE96CC9BC3A7": "9680B8EB-CE2A-4395-AF41-402801F4D6A6",     // Approaching Burj Khalifa (night)
        "B3BDC635-756D-4B82-B01A-A2620D1DBF10": "9680B8EB-CE2A-4395-AF41-402801F4D6A6",     // Approaching Burj Khalifa (night)
        "15F9B681-9EA8-4DD1-AD26-F111BC5CF64B": "E991AC0C-F272-44D8-88F3-05F44EDFE3AE",     // Marina 1
        "49790B7C-7D8C-466C-A09E-83E38B6BE87A": "E991AC0C-F272-44D8-88F3-05F44EDFE3AE",     // Marina 1
        "802866E6-4AAF-4A69-96EA-C582651391F1": "3FFA2A97-7D28-49EA-AA39-5BC9051B2745",     // Marina 2
        "D34A7B19-EC33-4300-B4ED-0C8BC494C035": "3FFA2A97-7D28-49EA-AA39-5BC9051B2745",     // Marina 2
        "02EA5DBE-3A67-4DFA-8528-12901DFD6CC1": "00BA71CD-2C54-415A-A68A-8358E677D750",     // Downtown
        "AC9C09DD-1D97-4013-A09F-B0F5259E64C3": "876D51F4-3D78-4221-8AD2-F9E78C0FD9B9",     // Sheikh Zayed Road (day)
        "DFA399FA-620A-4517-94D6-BF78BF8C5E5A": "876D51F4-3D78-4221-8AD2-F9E78C0FD9B9",     // Sheikh Zayed Road (day)
        "D388F00A-5A32-4431-A95C-38BF7FF7268D": "B8F204CE-6024-49AB-85F9-7CA2F6DCD226",     // Nuusuaq Peninsula
        "E4ED0B22-EB81-4D4F-A29E-7E1EA6B6D980": "B8F204CE-6024-49AB-85F9-7CA2F6DCD226",     // Nuusuaq Peninsula
        "30047FDA-3AE3-4E74-9575-3520AD77865B": "2F52E34C-39D4-4AB1-9025-8F7141FAA720",     // Ilulissat Icefjord day
        "7D4710EB-5BA4-42E6-AA60-68D77F67D9B9": "EE01F02D-1413-436C-AB05-410F224A5B7B",     // Ilulissat Icefjord Night
        "b8-1": "82BD33C9-B6D2-47E7-9C42-AA3B7758921A",                                     // Pu'u O 'Umi Night
        "b4-1": "258A6797-CC13-4C3A-AB35-4F25CA3BF474",                                     // Pu'u O 'Umi day
        "b1-1": "12E0343D-2CD9-48EA-AB57-4D680FB6D0C7",                                     // Waimanu Valley
        "b7-1": "499995FA-E51A-4ACE-8DFD-BDF8AFF6C943",                                     // Laupāhoehoe Nui
        "b6-2": "3D729CFC-9000-48D3-A052-C5BD5B7A6842",                                     // Kohala coastline
        "30313BC1-BF20-45EB-A7B1-5A6FFDBD2488": "E99FA658-A59A-4A2D-9F3B-58E7BDC71A9A",     // Hong Kong Victoria Harbour night
        "2A57BB93-1825-484C-9609-FF8580CAE77B": "E99FA658-A59A-4A2D-9F3B-58E7BDC71A9A",     // Hong Kong Victoria Harbour night
        "102C19D1-9D9F-48EC-B492-074C985C4D9F": "FE8E1F9D-59BA-4207-B626-28E34D810D0A",     // Hong Kong Victoria Harbour 1
        "786E674C-BB22-4AA9-9BD3-114D2020EC4D": "64EA30BD-C4B5-4CDD-86D7-DFE47E9CB9AA",     // Hong Kong Victoria Harbour 2
        "560E09E8-E89D-4ADB-8EEA-4754415383D4": "C8559883-6F3E-4AF2-8960-903710CD47B7",     // Hong Kong Victoria Peak
        "6E2FC8AC-832D-46CF-B306-BB2A05030C17": "001C94AE-2BA4-4E77-A202-F7DE60E8B1C8",     // Liwa oasis 1
        "88025454-6D58-48E8-A2DB-924988FAD7AC": "001C94AE-2BA4-4E77-A202-F7DE60E8B1C8",     // Liwa oasis 1
        "b6-3": "58754319-8709-4AB0-8674-B34F04E7FFE2",                                     // River Thames
        "b1-2": "F604AF56-EA77-4960-AEF7-82533CC1A8B3",                                     // River Thames near sunset
        "b3-1": "7F4C26C2-67C2-4C3A-8F07-8A7BF6148C97",                                     // River Times at Dusk
        "b5-2": "A5AAFF5D-8887-42BB-8AFD-867EF557ED85",                                     // Buckingham Palace
        "BEED64EC-2DB7-47E1-A67E-59C101E73C04": "CE279831-1CA7-4A83-A97B-FF1E20234396",     // LAX
        "829E69BA-BB53-4841-A138-4DF0C2A74236": "CE279831-1CA7-4A83-A97B-FF1E20234396",     // LAX
        "60CD8E2E-35CD-4192-A5A4-D5E10BFE158B": "92E48DE9-13A1-4172-B560-29B4668A87EE",     // Santa Monica Beach
        "B730433D-1B3B-4B99-9500-A286BF7A9940": "92E48DE9-13A1-4172-B560-29B4668A87EE",     // Santa Monica Beach
        "30A2A488-E708-42E7-9A90-B749A407AE1C": "35693AEA-F8C4-4A80-B77D-C94B20A68956",     // Harbor Freeway
        "A284F0BF-E690-4C13-92E2-4672D93E8DE5": "F5804DD6-5963-40DA-9FA0-39C0C6E6DEF9",     // Downtown
        "b3-2": "840FE8E4-D952-4680-B1A7-AC5BACA2C1F8",                                     // Upper East side
        "b4-2": "640DFB00-FBB9-45DA-9444-9F663859F4BC",                                     // Lower Manhattan (night)
        "b2-3": "44166C39-8566-4ECA-BD16-43159429B52F",                                     // Seventh Avenue
        "b7-2": "3BA0CFC7-E460-4B59-A817-B97F9EBB9B89",                                     // Central Park
        "b10-3": "EE533FBD-90AE-419A-AD13-D7A60E2015D6",                                    // Marin Headlands in Fog
        "b1-4": "3E94AE98-EAF2-4B09-96E3-452F46BC114E",                                     // Bay bridge night
        "b9-3": "DE851E6D-C2BE-4D9F-AB54-0F9CE994DC51",                                     // Bay and Golden Bridge
        "b7-3": "29BDF297-EB43-403A-8719-A78DA11A2948",                                     // Fisherman's Wharf
        "b3-3": "85CE77BF-3413-4A7B-9B0F-732E96229A73",                                     // Embarcadero, Market Street
    ]

    // Extra info to be merged for a given ID, as of right now only one known video
    static let mergeInfo = [
        "2F11E857-4F77-4476-8033-4A1E4610AFCC":
            ["url-1080-SDR": "https://sylvan.apple.com/Aerials/2x/Videos/DB_D011_C009_2K_SDR_HEVC.mov",
             "url-1080-HDR": "https://sylvan.apple.com/Aerials/2x/Videos/DB_D011_C009_2K_HDR_HEVC.mov",
             "url-4K-SDR": "https://sylvan.apple.com/Aerials/2x/Videos/DB_D011_C009_4K_SDR_HEVC.mov",
             "url-4K-HDR": "https://sylvan.apple.com/Aerials/2x/Videos/DB_D011_C009_4K_HDR_HEVC.mov", ],    // Dubai night 2
    ]

    // Look for a previously processed similar video
    //
    // tvOS11 and 12 JSON are using the same ID (and tvOS12 JSON always has better data,
    // so no need for a fancy merge)
    //
    // tvOS10 however JSON DOES NOT use the same ID, so we need to dupecheck on the h264
    // (only available format there) filename (they actually have different URLs !)
    static func findDuplicate(id: String, url1080pH264: String) -> (Bool, AerialVideo?) {
        // We blacklist some duplicates
        if url1080pH264 != "" {
            if blacklist.contains((URL(string: url1080pH264)?.lastPathComponent)!) {
                return (true, nil)
            }
        }

        // We also have a Dictionary of duplicates that need source merging
        for (pid, replace) in dupePairs where id == pid {
            for vid in VideoList.instance.videos where vid.id == replace {
                // Found dupe pair
                return (true, vid)
            }
        }

        for video in VideoList.instance.videos {
            if id == video.id {
                return (true, video)
            } else if url1080pH264 != "" && video.urls[.v1080pH264] != "" {
                if URL(string: url1080pH264)?.lastPathComponent == URL(string: video.urls[.v1080pH264]!)?.lastPathComponent {
                    return (true, video)
                }
            }
        }

        return (false, nil)
    }
}
