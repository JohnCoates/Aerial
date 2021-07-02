//
//  SpotifySong.swift
//  Aerial
//
//  Created by Guillaume Louel on 02/07/2021.
//  Copyright © 2021 Guillaume Louel. All rights reserved.
//
// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let spotifySong = try? newJSONDecoder().decode(SpotifySong.self, from: jsonData)

import Foundation

struct SpotifySong: Codable {
    let html: String
    let width, height: Int
    let version, providerName: String
    let providerURL: String
    let type, title: String
    let thumbnailURL: String?
    let thumbnailWidth, thumbnailHeight: Int

    enum CodingKeys: String, CodingKey {
        case html, width, height, version
        case providerName = "provider_name"
        case providerURL = "provider_url"
        case type, title
        case thumbnailURL = "thumbnail_url"
        case thumbnailWidth = "thumbnail_width"
        case thumbnailHeight = "thumbnail_height"
    }
}
