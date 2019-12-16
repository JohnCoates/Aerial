//
//  AerialView+Text.swift
//  Aerial
//
//  Created by Guillaume Louel on 06/12/2019.
//  Copyright © 2019 Guillaume Louel. All rights reserved.
//

import Foundation
import AVKit

extension AerialView {

//    func setupTextLayers(layer: CALayer) {
//        let offsets = LayerOffsets()
//
//        // Main description layer
//        textLayer = DescriptionLayer(withLayer: layer, isPreview: isPreview, offsets: offsets)
//        layer.addSublayer(textLayer)
//
//        // Clock Layer
///*
//        clockLayer = CATextLayer()
//        clockLayer.opacity = 0
//        clockLayer.shadowRadius = 10
//        clockLayer.shadowOpacity = 1.0
//        clockLayer.shadowColor = CGColor.black
//        layer.addSublayer(clockLayer)
//*/
//        // Message Layer
//        messageLayer = CATextLayer()
//        messageLayer.opacity = 0
//        messageLayer.shadowRadius = 10
//        messageLayer.shadowOpacity = 1.0
//        messageLayer.shadowColor = CGColor.black
//        layer.addSublayer(messageLayer)
//    }

    func setupGlitchWorkaroundLayer(layer: CALayer) {
        debugLog("Using dot workaround for video driver corruption")

        let workaroundLayer = CATextLayer()
        workaroundLayer.frame = self.bounds
        workaroundLayer.opacity = 0.5
        workaroundLayer.font = NSFont(name: "Helvetica Neue Medium", size: 4)
        workaroundLayer.fontSize = 4
        workaroundLayer.string = "."

        let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: workaroundLayer.font as Any]

        // Calculate bounding box
        let attrString = NSAttributedString(string: workaroundLayer.string as! String, attributes: attributes)
        let rect = attrString.boundingRect(with: layer.visibleRect.size, options: NSString.DrawingOptions.usesLineFragmentOrigin)

        workaroundLayer.frame = rect
        workaroundLayer.position = CGPoint(x: 2, y: 2)
        workaroundLayer.anchorPoint = CGPoint(x: 0, y: 0)
        layer.addSublayer(workaroundLayer)
    }

/*
    func addDescriptions(view: AerialView, player: AVPlayer, video: AerialVideo) {
        let poiStringProvider = PoiStringProvider.sharedInstance
        let preferences = Preferences.sharedInstance

        if preferences.showDescriptions {
            // We need to make sure we actually have descriptions to show.
            // Custom videos, and earlier tvOS videos may not
            if poiStringProvider.hasPoiKeys(video: video) {
                // Grab a sorted array of timestamps and the keys
                let (keys, times) = getKeysAndTimestamps(video: video)

                // Animate the very first one on it's own
                let str = poiStringProvider.getString(key: keys["0"]!, video: video)

                let duration = calculateAnimationDuration(times: times, current: times[0], video: video)
                let fadeAnimation = createFadeInOutAnimation(duration: duration)

                textLayer.update(string: str)
                textLayer.add(fadeAnimation, forKey: "textfade")

                // AVPlayer requires NSValues of CMTime
                var timevals = [NSValue]()
                for time in times {
                    timevals.append(NSValue(time: time))
                }

                // We then callback for each timestamp
                timeObserver = player.addBoundaryTimeObserver(forTimes: timevals, queue: DispatchQueue.main) {
                    // find closest timestamp to when we're waking up
                    var closest = 1000.0
                    var closestTime = CMTime.zero

                    for time in times {
                        let ts = time.seconds
                        let distance = abs(ts - player.currentTime().seconds)
                        if distance < closest {
                            closest = distance
                            closestTime = time
                        }
                    }

                    // Get the string for the current timestamp
                    let key = String(format: "%.0f", closestTime.seconds)
                    let str = poiStringProvider.getString(key: keys[key]!, video: video)

                    let duration = self.calculateAnimationDuration(times: times, current: closestTime, video: video)
                    let fadeAnimation = self.createFadeInOutAnimation(duration: duration)

                    self.textLayer.update(string: str)
                    self.textLayer.add(fadeAnimation, forKey: "textfade")
                }
            } else {
                // We don't have any extended description, using Secondary name (location) or video name (City)
                let str: String
                if video.secondaryName != "" {
                    str = video.secondaryName
                } else {
                    str = video.name
                }

                let duration = self.calculateAnimationDuration(times: [], current: CMTime.zero, video: video)
                let fadeAnimation = self.createFadeInOutAnimation(duration: duration)

                textLayer.update(string: str)
                textLayer.add(fadeAnimation, forKey: "textfade")
            }
        }
    }*/

    func repositionTextLayer(view: AerialView, position: Int) {
        let preferences = Preferences.sharedInstance
        var mx = CGFloat(preferences.marginX!)
        var my = CGFloat(preferences.marginY!)
        if !preferences.overrideMargins {
            mx = 50
            my = 50
        }
        if isPreview {
            mx = 10
            my = 10
        }

        if position == Preferences.DescriptionCorner.topLeft.rawValue {
            view.textLayer.anchorPoint = CGPoint(x: 0, y: 1)
            view.textLayer.position = CGPoint(x: mx, y: layer!.bounds.height-my)
            view.textLayer.alignmentMode = .left
        } else if position == Preferences.DescriptionCorner.bottomLeft.rawValue {
            view.textLayer.anchorPoint = CGPoint(x: 0, y: 0)
            view.textLayer.position = CGPoint(x: mx, y: my)
            view.textLayer.alignmentMode = .left
        } else if position == Preferences.DescriptionCorner.topRight.rawValue {
            view.textLayer.anchorPoint = CGPoint(x: 1, y: 1)
            view.textLayer.position = CGPoint(x: layer!.bounds.width-mx, y: layer!.bounds.height-my)
            view.textLayer.alignmentMode = .right
        } else if position == Preferences.DescriptionCorner.bottomRight.rawValue {
            view.textLayer.anchorPoint = CGPoint(x: 1, y: 0)
            view.textLayer.position = CGPoint(x: layer!.bounds.width-mx, y: my)
            view.textLayer.alignmentMode = .right
        }
    }
/*
    func setupAndRepositionExtra(view: AerialView, position: Int, duration: CFTimeInterval, isInitial: Bool, totalDuration: Double) {
        let preferences = Preferences.sharedInstance
        if preferences.showClock {
            if isInitial {
                if view.clockTimer == nil {
                    if #available(OSX 10.12, *) {
                        view.clockTimer =  Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (_) in
                            view.reRectClock(view: view)
                        })
                    }

                }

                let dateFormatter = DateFormatter()
                if preferences.withSeconds {
                    dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "j:mm:ss", options: 0, locale: Locale.current)
                } else {
                    dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "j:mm", options: 0, locale: Locale.current)
                }
                let dateString = dateFormatter.string(from: Date())

                view.clockLayer.string = dateString

                // We override font size on previews
                var fontSize = CGFloat(preferences.extraFontSize!)
                if layer!.bounds.height < 200 {
                    fontSize = 12
                }

                // Get font with a fallback in case
                var font = NSFont(name: "Monaco", size: 28)
                if let tryFont = NSFont(name: preferences.extraFontName!, size: fontSize) {
                    font = tryFont
                }

                // Make sure we change the layer font/size
                view.clockLayer.font = font
                view.clockLayer.fontSize = fontSize

                let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font as Any]

                // Calculate bounding box
                let str = NSAttributedString(string: dateString, attributes: attributes)
                let rect = str.boundingRect(with: layer!.visibleRect.size, options: NSString.DrawingOptions.usesLineFragmentOrigin)

                // Rebind frame
                view.clockLayer.frame = rect
            }

            if preferences.descriptionCorner == Preferences.DescriptionCorner.random.rawValue {
                view.clockLayer.add(createFadeInOutAnimation(duration: duration), forKey: "textfade")
            } else if isInitial && preferences.showDescriptionsMode == Preferences.DescriptionMode.always.rawValue {
                view.clockLayer.add(createFadeInOutAnimation(duration: totalDuration), forKey: "textfade")
            } else if preferences.showDescriptionsMode == Preferences.DescriptionMode.fade10seconds.rawValue {
                view.clockLayer.add(createFadeInOutAnimation(duration: duration), forKey: "textfade")
            }
        }

        if preferences.showMessage && preferences.showMessageString != "" {
            view.messageLayer.string = preferences.showMessageString

            // We override font size on previews
            var fontSize = CGFloat(preferences.extraFontSize!)
            if layer!.bounds.height < 200 {
                fontSize = 12
            }

            // Get font with a fallback in case
            var font = NSFont(name: "Helvetica Neue Medium", size: 28)
            if let tryFont = NSFont(name: preferences.extraFontName!, size: fontSize) {
                font = tryFont
            }

            // Make sure we change the layer font/size
            view.messageLayer.font = font
            view.messageLayer.fontSize = fontSize

            let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font as Any]

            // Calculate bounding box
            let str = NSAttributedString(string: preferences.showMessageString!, attributes: attributes)
            let rect = str.boundingRect(with: layer!.visibleRect.size, options: NSString.DrawingOptions.usesLineFragmentOrigin)

            // Rebind frame
            view.messageLayer.frame = rect

            if preferences.descriptionCorner == Preferences.DescriptionCorner.random.rawValue {
                view.messageLayer.add(createFadeInOutAnimation(duration: duration), forKey: "textfade")
            } else if isInitial && preferences.showDescriptionsMode == Preferences.DescriptionMode.always.rawValue {
                view.messageLayer.add(createFadeInOutAnimation(duration: totalDuration), forKey: "textfade")
            } else if preferences.showDescriptionsMode == Preferences.DescriptionMode.fade10seconds.rawValue {
                view.messageLayer.add(createFadeInOutAnimation(duration: duration), forKey: "textfade")
            }

        }

        if !isInitial && preferences.extraCorner == Preferences.ExtraCorner.same.rawValue &&
            preferences.showDescriptionsMode == Preferences.DescriptionMode.always.rawValue &&
            preferences.descriptionCorner != Preferences.DescriptionCorner.random.rawValue {
            animateClockAndMessageLayer(view: view, position: position)
        } else {
            if preferences.extraCorner == Preferences.ExtraCorner.same.rawValue {
                repositionClockAndMessageLayer(view: view, position: position, alone: false)
            } else if preferences.extraCorner == Preferences.ExtraCorner.hOpposed.rawValue {
                repositionClockAndMessageLayer(view: view, position: (position+2)%4, alone: true)
            } else if preferences.extraCorner == Preferences.ExtraCorner.dOpposed.rawValue {
                repositionClockAndMessageLayer(view: view, position: 3-position, alone: true)
            }
        }
    }*/ 

    func reRectClock(view: AerialView) {
        let preferences = Preferences.sharedInstance

        let dateFormatter = DateFormatter()
        if preferences.withSeconds {
            dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "j:mm:ss", options: 0, locale: Locale.current)
        } else {
            dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "j:mm", options: 0, locale: Locale.current)
        }

        let dateString = dateFormatter.string(from: Date())
        view.clockLayer.string = dateString
        // We override font size on previews
        var fontSize = CGFloat(preferences.extraFontSize!)
        if view.layer!.bounds.height < 200 {
            fontSize = 12
        }

        // Get font with a fallback in case
        var font = NSFont(name: "Monaco", size: 28)
        if let tryFont = NSFont(name: preferences.extraFontName!, size: fontSize) {
            font = tryFont
        }

        // Make sure we change the layer font/size
        view.clockLayer.font = font
        view.clockLayer.fontSize = fontSize

        let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font as Any]

        // Calculate bounding box
        let str = NSAttributedString(string: dateString, attributes: attributes)
        let rect = str.boundingRect(with: view.layer!.visibleRect.size, options: NSString.DrawingOptions.usesLineFragmentOrigin)

        // Rebind frame
        let oldRect = view.clockLayer.frame
        view.clockLayer.frame = CGRect(x: oldRect.minX, y: oldRect.minY, width: rect.maxX, height: rect.maxY)
    }

    func animateClockAndMessageLayer(view: AerialView, position: Int) {
        var clockDecal: CGFloat = 0
        var messageDecal: CGFloat = 0
        let preferences = Preferences.sharedInstance

        var mx = CGFloat(preferences.marginX!)
        var my = CGFloat(preferences.marginY!)
        if !preferences.overrideMargins {
            mx = 50
            my = 50
        }
        if isPreview {
            mx = 10
            my = 10
        }

        clockDecal += view.textLayer.visibleRect.height
        messageDecal += view.textLayer.visibleRect.height

        if preferences.showMessage {
            clockDecal += view.messageLayer.visibleRect.height
        }
        let duration = 1 + AerialView.textFadeDuration

        var cto, mto: CGPoint
        if position == Preferences.DescriptionCorner.topLeft.rawValue {
            cto = CGPoint(x: mx, y: layer!.bounds.height-my-clockDecal)
            mto = CGPoint(x: mx, y: layer!.bounds.height-my-messageDecal)
        } else if position == Preferences.DescriptionCorner.bottomLeft.rawValue {
            cto = CGPoint(x: mx, y: my+clockDecal)
            mto = CGPoint(x: mx, y: my+messageDecal)
        } else if position == Preferences.DescriptionCorner.topRight.rawValue {
            cto = CGPoint(x: layer!.bounds.width-mx, y: layer!.bounds.height-my-clockDecal)
            mto = CGPoint(x: layer!.bounds.width-mx, y: layer!.bounds.height-my-messageDecal)
        } else {
            cto = CGPoint(x: layer!.bounds.width-mx, y: my+clockDecal)
            mto = CGPoint(x: layer!.bounds.width-mx, y: my+messageDecal)
        }

        view.clockLayer.add(createMoveAnimation(layer: view.clockLayer, to: cto, duration: duration), forKey: "position")
        view.messageLayer.add(createMoveAnimation(layer: view.messageLayer, to: mto, duration: duration), forKey: "position")
    }

    func repositionClockAndMessageLayer(view: AerialView, position: Int, alone: Bool) {
        var clockDecal: CGFloat = 0
        var messageDecal: CGFloat = 0
        let preferences = Preferences.sharedInstance

        var mx = CGFloat(preferences.marginX!)
        var my = CGFloat(preferences.marginY!)
        if !preferences.overrideMargins {
            mx = 50
            my = 50
        }
        if isPreview {
            mx = 10
            my = 10
        }

        if !alone {
            clockDecal += view.textLayer.visibleRect.height
            messageDecal += view.textLayer.visibleRect.height
        }

        if preferences.showMessage {
            clockDecal += view.messageLayer.visibleRect.height
        }

        if position == Preferences.DescriptionCorner.topLeft.rawValue {
            view.clockLayer.anchorPoint = CGPoint(x: 0, y: 1)
            view.clockLayer.position = CGPoint(x: mx, y: layer!.bounds.height-my-clockDecal)
            view.messageLayer.anchorPoint = CGPoint(x: 0, y: 1)
            view.messageLayer.position = CGPoint(x: mx, y: layer!.bounds.height-my-messageDecal)
        } else if position == Preferences.DescriptionCorner.bottomLeft.rawValue {
            view.clockLayer.anchorPoint = CGPoint(x: 0, y: 0)
            view.clockLayer.position = CGPoint(x: mx, y: my+clockDecal)
            view.messageLayer.anchorPoint = CGPoint(x: 0, y: 0)
            view.messageLayer.position = CGPoint(x: mx, y: my+messageDecal)
        } else if position == Preferences.DescriptionCorner.topRight.rawValue {
            view.clockLayer.anchorPoint = CGPoint(x: 1, y: 1)
            view.clockLayer.position = CGPoint(x: layer!.bounds.width-mx, y: layer!.bounds.height-my-clockDecal)
            view.messageLayer.anchorPoint = CGPoint(x: 1, y: 1)
            view.messageLayer.position = CGPoint(x: layer!.bounds.width-mx, y: layer!.bounds.height-my-messageDecal)
        } else if position == Preferences.DescriptionCorner.bottomRight.rawValue {
            view.clockLayer.anchorPoint = CGPoint(x: 1, y: 0)
            view.clockLayer.position = CGPoint(x: layer!.bounds.width-mx, y: my+clockDecal)
            view.messageLayer.anchorPoint = CGPoint(x: 1, y: 0)
            view.messageLayer.position = CGPoint(x: layer!.bounds.width-mx, y: my+messageDecal)
        }
    }

}
