//
//  SourceInfo.swift
//  Aerial
//
//  Created by Guillaume Louel on 08/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Foundation

// swiftlint:disable:next type_body_length
struct SourceInfo {
    // Those videos will be ignored
    static let blacklist = ["b10-1.mov",           // Dupe of b1-1 (Hawaii, day)
                     "b10-2.mov",           // Dupe of b2-3 (New York, night)
                     "b10-4.mov",           // Dupe of b2-4 (San Francisco, night)
                     "b9-1.mov",            // Dupe of b2-2 (Hawaii, day)
                     "b9-2.mov",            // Dupe of b3-1 (London, night)
                     "comp_LA_A005_C009_v05_t9_6M.mov",     // Low quality version of Los Angeles day 687B36CB-BA5D-4434-BA99-2F2B8B6EC163
                     "comp_LA_A009_C009_t9_6M_tag0.mov"
                     ]    // Low quality version of Los Angeles night 89B1643B-06DD-4DEC-B1B0-774493B0F7B7

    // This is used for videos where URLs should be merged with different ID
    // This is used to dedupe old versions of videos
    // old : new
    static let dupePairs = [
        "A2BE2E4A-AD4B-428A-9C41-BDAE1E78E816": "12318CCB-3F78-43B7-A854-EFDCCE5312CD",     // California to Vegas (v7 -> v8)
        "6A74D52E-2447-4B84-AE45-0DEF2836C3CC": "7825C73A-658F-48EE-B14C-EC56673094AC",     // China
        "7825C73A-658F-48EE-B14C-EC56673094AC": "6324F6EB-E0F1-468F-AC2E-A983EBDDD53B",     // China again
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
        "391BDF6E-3279-4CE1-9CA5-0F82811452D7": "83C65C90-270C-4490-9C69-F51FE03D7F06"  // Seals tvOS 15 is reusing an old id
    ]

    // Extra info to be merged for a given ID, as of right now only one known video
    static let mergeInfo = [
        "2F11E857-4F77-4476-8033-4A1E4610AFCC":
            ["url-1080-SDR": "https://sylvan.apple.com/Aerials/2x/Videos/DB_D011_C009_2K_SDR_HEVC.mov",
             "url-1080-HDR": "https://sylvan.apple.com/Aerials/2x/Videos/DB_D011_C009_2K_HDR_HEVC.mov",
             "url-4K-SDR": "https://sylvan.apple.com/Aerials/2x/Videos/DB_D011_C009_4K_SDR_HEVC.mov",
             "url-4K-HDR": "https://sylvan.apple.com/Aerials/2x/Videos/DB_D011_C009_4K_HDR_HEVC.mov" ]    // Dubai night 2
    ]

    static let cityVideos = [
        "b8-3", // San Francisco - Alamo Square
        "9680B8EB-CE2A-4395-AF41-402801F4D6A6", // Dubai - Approaching Burj Khalifa
        "3E94AE98-EAF2-4B09-96E3-452F46BC114E", // San Francisco - Bay Bridge
        "4AD99907-9E76-408D-A7FC-8429FF014201", // San Francisco - Bay and Embarcadero
        "A5AAFF5D-8887-42BB-8AFD-867EF557ED85", // London - Buckingham Palace
        "3BA0CFC7-E460-4B59-A817-B97F9EBB9B89", // New York - Central Park
        "00BA71CD-2C54-415A-A68A-8358E677D750", // Dubai - Downtown
        "F5804DD6-5963-40DA-9FA0-39C0C6E6DEF9", // Los Angeles - Downtown
        "b6-4", // San Francisco - Downtown and Coit Tower
        "b2-4", // San Francisco - Downtown and Sutro Tower
        "85CE77BF-3413-4A7B-9B0F-732E96229A73", // San Francisco - Embarcadero, Market Street
        "b5-3", // San Francisco - Embarcadero, Market Street
        "29BDF297-EB43-403A-8719-A78DA11A2948", // San Francisco - Fisherman’s Wharf
        "35693AEA-F8C4-4A80-B77D-C94B20A68956", // Los Angeles - Harbor Freeway
        "CE279831-1CA7-4A83-A97B-FF1E20234396", // Los Angeles - Los Angeles Int’l Airport
        "640DFB00-FBB9-45DA-9444-9F663859F4BC", // New York - Lower Manhattan
        "b1-3", // New York - Lower Manhattan
        "E991AC0C-F272-44D8-88F3-05F44EDFE3AE", // Dubai - Marina 1
        "3FFA2A97-7D28-49EA-AA39-5BC9051B2745", // Dubai - Marina 2
        "58754319-8709-4AB0-8674-B34F04E7FFE2", // London - River Thames
        "7F4C26C2-67C2-4C3A-8F07-8A7BF6148C97", // London - River Thames at Dusk
        "F604AF56-EA77-4960-AEF7-82533CC1A8B3", // London - River Thames near Sunset
        "44166C39-8566-4ECA-BD16-43159429B52F", // New York - Seventh Avenue
        "876D51F4-3D78-4221-8AD2-F9E78C0FD9B9", // Dubai - Sheikh Zayed Road
        "2F11E857-4F77-4476-8033-4A1E4610AFCC", // Dubai - Sheikh Zayed Road
        "840FE8E4-D952-4680-B1A7-AC5BACA2C1F8", // New York - Upper East Side
        "E99FA658-A59A-4A2D-9F3B-58E7BDC71A9A", // Hong Kong - Victoria Harbour
        "FE8E1F9D-59BA-4207-B626-28E34D810D0A", // Hong Kong - Victoria Harbour 1
        "64EA30BD-C4B5-4CDD-86D7-DFE47E9CB9AA", // Hong Kong - Victoria Harbour 2
        "C8559883-6F3E-4AF2-8960-903710CD47B7", // Hong Kong - Victoria Peak
        "024891DE-B7F6-4187-BFE0-E6D237702EF0" // Hong Kong - Wan Chai
    ]

    static let countrySideVideos = [
        "DE851E6D-C2BE-4D9F-AB54-0F9CE994DC51", // San Francisco - Bay and Golden Gate
        "72B4390D-DF1D-4D51-B179-229BBAEFFF2C", // San Francisco - Golden Gate from SF
        "b8-2", // San Francisco - Marin Headlands
        "EE533FBD-90AE-419A-AD13-D7A60E2015D6", // San Francisco - Marin Headlands in Fog
        "89B1643B-06DD-4DEC-B1B0-774493B0F7B7", // Los Angeles - Griffith Observatory
        "EC67726A-8212-4C5E-83CF-8412932740D2", // Los Angeles - Hollywood Hills
        "b4-3" // San Francisco - Presidio to Golden Gate
    ]

    static let beachVideos = [
        "b2-2", // Hawaii - Honopū Valley
        "3D729CFC-9000-48D3-A052-C5BD5B7A6842", // Hawaii - Kohala Coastline
        "12E0343D-2CD9-48EA-AB57-4D680FB6D0C7", // Hawaii - Laupāhoehoe Nui
        "92E48DE9-13A1-4172-B560-29B4668A87EE" // Los Angeles - Santa Monica Beach
    ]

    static let spaceVideos = [
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
        "87060EC2-D006-4102-98CC-3005C68BB343"             // South Africa to North Asia

    ]

    static let seaVideos = [
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
        "391BDF6E-3279-4CE1-9CA5-0F82811452D7" // Seals (new version)
    ]

    static let timeInformation = [
        "A837FA8C-C643-4705-AE92-074EFDD067F7": "night",    // Africa Night
        "03EC0F5E-CCA8-4E0A-9FEC-5BD1CE151182": "sunrise", // Space - Antartica
        "64D11DAB-3B57-4F14-AD2F-E59A9282FA44": "sunset", // Space - Atlantic Ocean to Spain and France
        "81337355-E156-4242-AAF4-711768D30A54": "night", // Space - Australia
        "A2BE2E4A-AD4B-428A-9C41-BDAE1E78E816": "night",    // California to Vegas (v7)
        "12318CCB-3F78-43B7-A854-EFDCCE5312CD": "night",    // California to Vegas (v8)
        "6A74D52E-2447-4B84-AE45-0DEF2836C3CC": "night",    // China
        "7825C73A-658F-48EE-B14C-EC56673094AC": "night",    // China (new id)

        "E5DB138A-F04E-4619-B896-DE5CB538C534": "night",    // Italy to Asia
        "F439B0A7-D18C-4B14-9681-6520E6A74FE9": "sunset",    // Iran and Afghanistan
        "62A926BE-AA0B-4A34-9653-78C4F130543F": "night",    // Ireland to Asia
        "7C643A39-C0B2-4BA0-8BC2-2EAA47CC580E": "night",    // Ireland to Asia
        "6C3D54AE-0871-498A-81D0-56ED24E5FE9F": "night",    // Korean and Japan Night (v17)
        "009BA758-7060-4479-8EE8-FB9B40C8FB97": "night",    // Korean and Japan Night (v18)
        "B1B5DDC5-73C8-4920-8133-BACCE38A08DE": "night", // Space - Mexico City to New York
        "78911B7E-3C69-47AD-B635-9C2486F6301D": "sunrise", // Space - New Zealand
        "737E9E24-49BE-4104-9B72-F352DE1AD2BF": "sunrise", // Space - North America Aurora
        "87060EC2-D006-4102-98CC-3005C68BB343": "sunset", // Space - South Africa to North Asia
        "63C042F0-90EF-4A95-B7CC-CC9A64BF8421": "sunset", // Space - West Africa to the Alps

        "044AD56C-A107-41B2-90CC-E60CCACFBCF5": "sunset", // China - Great Wall 3
        "EE01F02D-1413-436C-AB05-410F224A5B7B": "sunset", // Greenland - Ilulissat Icefjord
        "B8F204CE-6024-49AB-85F9-7CA2F6DCD226": "sunrise", // Greenland - Nuussuaq Peninsula
        "82BD33C9-B6D2-47E7-9C42-AA3B7758921A": "sunset", // Hawaii - Pu‘u O ‘Umi

        "9680B8EB-CE2A-4395-AF41-402801F4D6A6": "night",    // Approaching Burj Khalifa
        "3E94AE98-EAF2-4B09-96E3-452F46BC114E": "night", // San Francisco - Bay Bridge
        "4AD99907-9E76-408D-A7FC-8429FF014201": "sunset", // San Francisco - Bay and Embarcadero
        "00BA71CD-2C54-415A-A68A-8358E677D750": "sunrise", // Dubai - Downtown
        "F5804DD6-5963-40DA-9FA0-39C0C6E6DEF9": "night", // Los Angeles - Downtown

        "b6-4": "sunset", // San Francisco - Downtown and Coit Tower
        "b2-4": "sunset", // San Francisco - Downtown and Sutro Tower
        "85CE77BF-3413-4A7B-9B0F-732E96229A73": "sunrise", // San Francisco - Embarcadero, Market Street
        "b5-3": "sunset", // San Francisco - Embarcadero, Market Street
        "29BDF297-EB43-403A-8719-A78DA11A2948": "sunrise", // San Francisco - Fisherman’s Wharf
        "640DFB00-FBB9-45DA-9444-9F663859F4BC": "sunset", // New York - Lower Manhattan
        "7F4C26C2-67C2-4C3A-8F07-8A7BF6148C97": "sunset", // London - River Thames at Dusk
        "F604AF56-EA77-4960-AEF7-82533CC1A8B3": "sunset", // London - River Thames near Sunset
        "44166C39-8566-4ECA-BD16-43159429B52F": "night", // New York - Seventh Avenue
        "2F11E857-4F77-4476-8033-4A1E4610AFCC": "night", // Dubai - Sheikh Zayed Road
        "E99FA658-A59A-4A2D-9F3B-58E7BDC71A9A": "sunset", // Hong Kong - Victoria Harbour

        "3D729CFC-9000-48D3-A052-C5BD5B7A6842": "sunset", // Hawaii - Kohala Coastline

        "89B1643B-06DD-4DEC-B1B0-774493B0F7B7": "sunset", // Los Angeles - Griffith Observatory
        "EC67726A-8212-4C5E-83CF-8412932740D2": "sunset", // Los Angeles - Hollywood Hills
        "EE533FBD-90AE-419A-AD13-D7A60E2015D6": "sunrise", // San Francisco - Marin Headlands in Fog
        "b4-3": "sunrise" // San Francisco - Presidio to Golden Gate

        // "BAF76353-3475-4855-B7E1-CE96CC9BC3A7": "night",    // Dubai
        // "30313BC1-BF20-45EB-A7B1-5A6FFDBD2488": "night",    // Hong Kong
        // "A284F0BF-E690-4C13-92E2-4672D93E8DE5": "night",    // Los Angeles (old ?)

        // "44166C39-8566-4ECA-BD16-43159429B52F": "night",    // Seventh Avenue
    ]

    // Extra POI
    static let mergePOI = [
            "b6-1": "C001_C005_",    // China day 4
            "b2-1": "C004_C003_",    // China day 5
            "b5-1": "C003_C003_",    // China day 6
            "7D4710EB-5BA4-42E6-AA60-68D77F67D9B9": "GL_G010_C006_",             // Greenland night 1
            "b7-1": "H007_C003",                                                 // Hawaii day 1
            "b1-1": "H005_C012_",                                                // Hawaii day 2
            "b2-2": "H010_C006_",                                                // Hawaii day 3
            "b4-1": "H004_C007_",                                                // Hawaii day 4
            "b6-2": "H012_C009_",                                                // Hawaii night 1
            "b8-1": "H004_C009_",                                                // Hawaii night 2
            "6E2FC8AC-832D-46CF-B306-BB2A05030C17": "LW_L001_C006_",             // Liwa day 1 LW_L001_C006_0
            "b6-3": "L010_C006_",                                                // London day 1
            "b5-2": "L007_C007_",                                                // London day 2
            "b1-2": "L012_C002_",                                                // London night 1
            "b3-1": "L004_C011_",                                                // London night 2
            "A284F0BF-E690-4C13-92E2-4672D93E8DE5": "LA_A011_C003_",             // Los Angeles night 3
            "b7-2": "N008_C009_",                                                // New York day 1
            "b1-3": "N006_C003_",                                                // New York day 2
            "b3-2": "N003_C006_",                                                // New York day 3
            "b2-3": "N013_C004_",                                                // New York night 1
            "b4-2": "N008_C003_",                                                // New York night 2
            "b8-2": "A008_C007_",                                                // San Francisco day 1
            // "b10-3": ,                                               // San Francisco day 2
            "b9-3": "A006_C003_",                                                // San Francisco day 3
            // "b8-3":"",     San Francisco day 4 (no extra poi ?)
            "b3-3": "A012_C014_",                                                // San Francisco day 5
                                                                                //   maybe A013_C004 ?
            "b4-3": "A013_C005_",                                                // San Francisco day 6
            "b6-4": "A004_C012_",                                                // San Francisco night 1
            "b7-3": "A007_C017_",                                                // San Francisco night 2
            "b5-3": "A015_C014_",                                                // San Francisco night 3
            "b1-4": "A015_C018_",                                                // San Francisco night 4
            "b2-4": "A018_C014_",                                                 // San Francisco night 5
            "2F11E857-4F77-4476-8033-4A1E4610AFCC": "DB_D008_C010_"        // Stealing the day description for the night one

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

    static func getSceneForVideo(id: String) -> SourceScene? {
        if seaVideos.contains(id) {
            return .sea
        } else if spaceVideos.contains(id) {
            return .space
        } else if cityVideos.contains(id) {
            return .city
        } else if countrySideVideos.contains(id) {
            return .countryside
        } else if beachVideos.contains(id) {
            return .beach
        }

        return nil
    }
}
