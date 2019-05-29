// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let customVideoFolders = try CustomVideoFolders(json)

import Foundation

// MARK: - CustomVideoFolders
class CustomVideoFolders: Codable {
    var folders: [Folder]

    enum CodingKeys: String, CodingKey {
        case folders = "folders"
    }

    init(folders: [Folder]) {
        self.folders = folders
    }
}

// MARK: CustomVideoFolders convenience initializers and mutators

extension CustomVideoFolders {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(CustomVideoFolders.self, from: data)
        self.init(folders: me.folders)
    }

    convenience init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    convenience init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        folders: [Folder]? = nil
        ) -> CustomVideoFolders {
        return CustomVideoFolders(
            folders: folders ?? self.folders
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Folder
class Folder: Codable {
    var url: String
    var label: String
    var assets: [Asset]

    enum CodingKeys: String, CodingKey {
        case url = "url"
        case label = "label"
        case assets = "assets"
    }

    init(url: String, label: String, assets: [Asset]) {
        self.url = url
        self.label = label
        self.assets = assets
    }
}

// MARK: Folder convenience initializers and mutators

extension Folder {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Folder.self, from: data)
        self.init(url: me.url, label: me.label, assets: me.assets)
    }

    convenience init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    convenience init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        url: String? = nil,
        label: String? = nil,
        assets: [Asset]? = nil
        ) -> Folder {
        return Folder(
            url: url ?? self.url,
            label: label ?? self.label,
            assets: assets ?? self.assets
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Asset
class Asset: Codable {
    var pointsOfInterest: [String: String]
    var url: String
    var accessibilityLabel: String
    var id: String
    var time: String

    enum CodingKeys: String, CodingKey {
        case pointsOfInterest = "pointsOfInterest"
        case url = "url"
        case accessibilityLabel = "accessibilityLabel"
        case id = "id"
        case time = "time"
    }

    init(pointsOfInterest: [String: String], url: String, accessibilityLabel: String, id: String, time: String) {
        self.pointsOfInterest = pointsOfInterest
        self.url = url
        self.accessibilityLabel = accessibilityLabel
        self.id = id
        self.time = time
    }
}

// MARK: Asset convenience initializers and mutators

extension Asset {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Asset.self, from: data)
        self.init(pointsOfInterest: me.pointsOfInterest, url: me.url, accessibilityLabel: me.accessibilityLabel, id: me.id, time: me.time)
    }

    convenience init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    convenience init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        pointsOfInterest: [String: String]? = nil,
        url: String? = nil,
        accessibilityLabel: String? = nil,
        id: String? = nil,
        time: String? = nil
        ) -> Asset {
        return Asset(
            pointsOfInterest: pointsOfInterest ?? self.pointsOfInterest,
            url: url ?? self.url,
            accessibilityLabel: accessibilityLabel ?? self.accessibilityLabel,
            id: id ?? self.id,
            time: time ?? self.time
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Helper functions for creating encoders and decoders

func newJSONDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        decoder.dateDecodingStrategy = .iso8601
    }
    return decoder
}

func newJSONEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        encoder.dateEncodingStrategy = .iso8601
    }
    return encoder
}
