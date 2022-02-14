//
//  MessageLayer.swift
//  Aerial
//
//  Created by Guillaume Louel on 12/12/2019.
//  Copyright © 2019 Guillaume Louel. All rights reserved.
//

import Foundation
import AVKit

class MessageLayer: AnimationTextLayer {
    var config: PrefsInfo.Message?
    var wasSetup = false
    var messageTimer: Timer?

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Our inits
    override init(withLayer: CALayer, isPreview: Bool, offsets: LayerOffsets, manager: LayerManager) {
        super.init(withLayer: withLayer, isPreview: isPreview, offsets: offsets, manager: manager)

        // We start with a full opacity
        self.opacity = 1
    }

    convenience init(withLayer: CALayer, isPreview: Bool, offsets: LayerOffsets, manager: LayerManager, config: PrefsInfo.Message) {
        self.init(withLayer: withLayer, isPreview: isPreview, offsets: offsets, manager: manager)
        self.config = config

        // Set our layer's font & corner now
        (self.font, self.fontSize) = getFont(name: config.fontName,
                                             size: config.fontSize)
        self.corner = config.corner
    }

    override func setupForVideo(video: AerialVideo, player: AVPlayer) {
        guard let config = config else {
            return
        }

        // Only run this once, if enabled
        if !wasSetup {
            wasSetup = true

            switch config.messageType {
            case .text:
                update(string: config.message)
            case .shell:
                update(string: "")
                DispatchQueue.global().async {
                    debugLog("setting up initial")
                    let result = self.runShell()
                    
                    if let result = result {
                        // Do it on the main queue...
                        DispatchQueue.main.async {
                            debugLog("updating initial " + result)
                            self.update(string: result)
                        }
                    }
                }
                //setupRefresh()
            case .textfile:
                // TODO
                update(string: config.message)
            }

            let fadeAnimation = self.createFadeInAnimation()
            add(fadeAnimation, forKey: "textfade")
        }
    }

    func setupRefresh() {
        debugLog("setting up refresh")
        guard let config = config else {
            return
        }

        guard config.refreshPeriodicity != .never else {
            return
        }

        if #available(OSX 10.12, *) {
            var interval = 0.0
            switch config.refreshPeriodicity {
            case .never:
                interval = 1
            case .tenseconds:
                interval = 10
            case .thirtyseconds:
                interval = 30
            case .oneminute:
                interval = 60
            case .fiveminutes:
                interval = 300
            case .tenminutes:
                interval = 600
            }

            messageTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { [self] (_) in

                DispatchQueue.global().async {
                    let result = self.runShell()
                    self.update(string: result ?? "")
                }
            })
        }
    }

    func runShell() -> String? {
        guard let config = config else {
            return nil
        }

        if config.shellScript != "" {
            if FileManager.default.fileExists(atPath: PrefsInfo.message.shellScript) {
                let (result, _) = Aerial.shell(launchPath: PrefsInfo.message.shellScript)

                debugLog("result " + (result ?? ""))
                if let res = result {
                    return res
                }
            }
        }

        return nil
    }
}
