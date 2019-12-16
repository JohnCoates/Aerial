//
//  PWC+Info.swift
//  Aerial
//
//  Created by Guillaume Louel on 16/12/2019.
//  Copyright © 2019 Guillaume Louel. All rights reserved.
//

import Foundation

extension PreferencesWindowController {

    func setupInfoTab() {
        print("info source")
        infoSource = InfoTableSource()
        infoTableView.dataSource = infoSource
        infoTableView.delegate = infoSource
    }
}
