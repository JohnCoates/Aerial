//
//  CustomVideoFolders+helpers.swift
//  Aerial
//
//  Created by Guillaume Louel on 24/05/2019.
//  Copyright © 2019 John Coates. All rights reserved.
//

import Foundation

// Helpers added on top of our generated json class
extension CustomVideoFolders {
    func hasFolder(withUrl: String) -> Bool {
        for folder in folders where folder.url == withUrl {
            return true
        }

        return false
    }

    func getFolderIndex(withUrl: String) -> Int {
        var index = 0
        for folder in folders {
            if folder.url == withUrl {
                return index
            }
            index += 1
        }
        return -1
    }

    func getFolder(withUrl: String) -> Folder? {
        for folder in folders where folder.url == withUrl {
            return folder
        }

        return nil
    }
}

extension Folder {
    func hasAsset(withUrl: String) -> Bool {
        for asset in assets where asset.url == withUrl {
            return true
        }
        return false
    }
}
