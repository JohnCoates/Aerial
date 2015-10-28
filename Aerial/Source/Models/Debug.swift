//
//  Debug.swift
//  Aerial
//
//  Created by John Coates on 10/28/15.
//  Copyright © 2015 John Coates. All rights reserved.
//

import Foundation


func debugLog(message:String) {
    #if DEBUG
        NSLog(message);
    #endif
}