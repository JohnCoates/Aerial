//
//  DescriptionCellView.swift
//  Aerial
//
//  Created by Guillaume Louel on 09/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa

class DescriptionCellView: NSTableCellView {

    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var descriptionLabel: NSTextField!
    @IBOutlet weak var lastUpdatedLabel: NSTextField!
    @IBOutlet weak var videoCount: NSTextField!
    @IBOutlet weak var imageScene1: NSImageView!
    @IBOutlet weak var imageScene2: NSImageView!
    @IBOutlet weak var imageScene3: NSImageView!
    @IBOutlet weak var imageScene4: NSImageView!

    /// The item that represent the row in the outline view
    /// We may potentially use this cell for multiple outline views so let's make it generic
    var item: Any?

    /// The delegate of the cell
    // var delegate: CheckboxCellViewDelegate?

    override func awakeFromNib() {
        //checkboxButton.target = self
        //checkboxButton.action = #selector(self.didChangeState(_:))
    }

    /// Notify the delegate that the checkbox's state has changed
    @objc private func didChangeState(_ sender: NSObject) {
        //delegate?.checkboxCellView(self, didChangeState: checkboxButton.state)
    }
}
