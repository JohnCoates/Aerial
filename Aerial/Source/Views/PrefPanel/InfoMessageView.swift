//
//  InfoMessageView.swift
//  Aerial
//
//  Created by Guillaume Louel on 18/12/2019.
//  Copyright © 2019 Guillaume Louel. All rights reserved.
//

import Cocoa

class InfoMessageView: NSView, NSTextViewDelegate {
    @IBOutlet var messageTextView: NSTextView!

    func setStates() {
        messageTextView.delegate = self

        messageTextView.string = PrefsInfo.message.message
    }

    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else { return }
        print(textView.string)
        PrefsInfo.message.message = textView.string
    }
}
