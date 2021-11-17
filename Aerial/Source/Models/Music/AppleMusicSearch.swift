//
//  AppleMusicSearch.swift
//  Aerial
//
//  Created by Guillaume Louel on 08/07/2021.
//  Copyright © 2021 Guillaume Louel. All rights reserved.
//
// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let appleMusicSearch = try? newJSONDecoder().decode(AppleMusicSearch.self, from: jsonData)

import Foundation

// MARK: - AppleMusicSearch
struct AppleMusicSearch: Codable {
    let results: AppleMusicSearchResults?
    let meta: Meta?
}

// MARK: - Meta
struct Meta: Codable {
    let results: MetaResults?
}

// MARK: - MetaResults
struct MetaResults: Codable {
    let order, rawOrder: [String]?
}

// MARK: - AppleMusicSearchResults
struct AppleMusicSearchResults: Codable {
    let albums: PurpleAlbums?
}

// MARK: - Albums
struct PurpleAlbums: Codable {
    let href: String?
    let data: [PurpleDatum]?
}

// MARK: - Datum
struct PurpleDatum: Codable {
    let id, type, href: String?
    let attributes: PurpleAttributes?
}

// MARK: - Attributes
struct PurpleAttributes: Codable {
    let artwork: PurpleArtwork?
    let artistName: String?
    let isSingle: Bool?
    let url: String?
    let isComplete: Bool?
    let genreNames: [String]?
    let trackCount: Int?
    let isMasteredForItunes: Bool?
    let releaseDate, name, recordLabel, upc: String?
    let copyright: String?
    let playParams: PurplePlayParams?
    let isCompilation: Bool?
}

// MARK: - Artwork
struct PurpleArtwork: Codable {
    let width, height: Int?
    let url, bgColor, textColor1, textColor2: String?
    let textColor3, textColor4: String?
}

// MARK: - PlayParams
struct PurplePlayParams: Codable {
    let id, kind: String?
}
