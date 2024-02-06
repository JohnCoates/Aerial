//
//  URL+subdirectories.swift
//  Aerial
//
//  Created by Guillaume Louel on 05/02/2024.
//  Copyright © 2024 Guillaume Louel. All rights reserved.
//

import Foundation

extension URL {
    var isDirectory: Bool {
        return (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }

    var subDirectories: [URL] {
        guard isDirectory else { return [] }
        return (try? FileManager.default.contentsOfDirectory(at: self,
                    includingPropertiesForKeys: nil,
                    options: [.skipsHiddenFiles]).filter(\.isDirectory)) ?? []
    }
}
