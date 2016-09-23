//
//  CheckCellView.swift
//  Aerial
//
//  Created by John Coates on 10/24/15.
//  Copyright © 2015 John Coates. All rights reserved.
//

import Cocoa

class CheckCellView: NSTableCellView {

    @IBOutlet var checkButton: NSButton!
    var onCheck: ((Bool) -> (Void))?
    
    override required init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func awakeFromNib() {
        checkButton.target = self
        checkButton.action = #selector(CheckCellView.check(_:))
    }
    
    func check(_ button: AnyObject?) {        
        guard let onCheck = self.onCheck else {
            return
        }
        
        onCheck(checkButton.state == NSOnState)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
}
