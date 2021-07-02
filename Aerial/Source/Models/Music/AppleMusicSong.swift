//
//  AppleMusicSong.swift
//  Aerial
//
//  Created by Guillaume Louel on 30/06/2021.
//  Copyright © 2021 Guillaume Louel. All rights reserved.
//
// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let appleMusicSong = try? newJSONDecoder().decode(AppleMusicSong.self, from: jsonData)

import Foundation

// MARK: - AppleMusicSong
struct AppleMusicSong: Codable {
    let data: [AppleMusicSongDatum]?
}

// MARK: - AppleMusicSongDatum
struct AppleMusicSongDatum: Codable {
    let id, type, href: String?
    let attributes: Attributes?
    let relationships: Relationships?
}

// MARK: - Attributes
struct Attributes: Codable {
    let previews: [Preview]?
    let artwork: Artwork?
    let artistName: String?
    let url: String?
    let discNumber: Int?
    let genreNames: [String]?
    let durationInMillis: Int?
    let releaseDate, name, isrc: String?
    let hasLyrics: Bool?
    let albumName: String?
    let playParams: PlayParams?
    let trackNumber: Int?
    let contentRating: String?
}

// MARK: - Artwork
struct Artwork: Codable {
    let width, height: Int?
    let url, bgColor, textColor1, textColor2: String?
    let textColor3, textColor4: String?
}

// MARK: - PlayParams
struct PlayParams: Codable {
    let id, kind: String?
}

// MARK: - Preview
struct Preview: Codable {
    let url: String?
}

// MARK: - Relationships
struct Relationships: Codable {
    let artists, albums: Albums?
}

// MARK: - Albums
struct Albums: Codable {
    let href: String?
    let data: [AlbumsDatum]?
}

// MARK: - AlbumsDatum
struct AlbumsDatum: Codable {
    let id, type, href: String?
}
