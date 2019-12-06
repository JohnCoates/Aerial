//
//  AerialView+Text.swift
//  Aerial
//
//  Created by Guillaume Louel on 06/12/2019.
//  Copyright © 2019 John Coates. All rights reserved.
//

import Foundation
import AVKit

extension AerialView {

    func setupTextLayers(layer: CALayer) {
        // Main description layer
        textLayer = CATextLayer()
        textLayer.frame = layer.bounds  // Same size as the screen
        textLayer.opacity = 0
        textLayer.shadowRadius = 10
        textLayer.shadowOpacity = 1.0
        textLayer.shadowColor = CGColor.black
        layer.addSublayer(textLayer)

        // Clock Layer
        clockLayer = CATextLayer()
        clockLayer.opacity = 0
        clockLayer.shadowRadius = 10
        clockLayer.shadowOpacity = 1.0
        clockLayer.shadowColor = CGColor.black
        layer.addSublayer(clockLayer)

        // Message Layer
        messageLayer = CATextLayer()
        messageLayer.opacity = 0
        messageLayer.shadowRadius = 10
        messageLayer.shadowOpacity = 1.0
        messageLayer.shadowColor = CGColor.black
        layer.addSublayer(messageLayer)
    }

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

    // swiftlint:disable:next cyclomatic_complexity
    func addDescriptions(view: AerialView, player: AVPlayer, video: AerialVideo) {
        let poiStringProvider = PoiStringProvider.sharedInstance
        let preferences = Preferences.sharedInstance

        if preferences.showDescriptions {
            // Preventively, make sure we have poi as tvOS11/10 videos won't have them
            if (!video.poi.isEmpty && poiStringProvider.loadedDescriptions) ||
                (!video.communityPoi.isEmpty && !poiStringProvider.getPoiKeys(video: video).isEmpty) {
                // Collect all the timestamps from the JSON
                var times = [NSValue]()
                let keys = poiStringProvider.getPoiKeys(video: video)

                for pkv in keys {
                    let timeStamp = Double(pkv.key)!
                    times.append(NSValue(time: CMTime(seconds: timeStamp, preferredTimescale: 1)))
                }
                // The JSON isn't sorted so we fix that
                times.sort(by: { ($0 as! CMTime).seconds < ($1 as! CMTime).seconds })

                // Animate the very first one on it's own
                let str = poiStringProvider.getString(key: keys["0"]!, video: video)

                var fadeAnimation: CAKeyframeAnimation

                if preferences.showDescriptionsMode == Preferences.DescriptionMode.fade10seconds.rawValue {
                    fadeAnimation = createFadeInOutAnimation(duration: 11)
                } else {
                    // Always show mode, if there's more than one point, use that, if not either use known video duration or some hardcoded duration
                    if times.count > 1 {
                        let duration = (times[1] as! CMTime).seconds - 1
                        fadeAnimation = createFadeInOutAnimation(duration: duration)
                    } else if video.duration > 0 {
                        fadeAnimation = createFadeInOutAnimation(duration: video.duration - 1)
                    } else {
                        // We should have the duration, if we don't, hardcode the longest known duration
                        fadeAnimation = createFadeInOutAnimation(duration: 807)
                    }
                }

                view.textLayer.add(fadeAnimation, forKey: "textfade")
                if video.duration > 0 {
                    setupTextLayer(view: view, string: str, duration: fadeAnimation.duration, isInitial: true, totalDuration: video.duration - 1)
                } else {
                    setupTextLayer(view: view, string: str, duration: fadeAnimation.duration, isInitial: true, totalDuration: 807)
                }

                let mainQueue = DispatchQueue.main

                // We then callback for each timestamp
                timeObserver = player.addBoundaryTimeObserver(forTimes: times, queue: mainQueue) {
                    var isLastTimeStamp = true
                    var intervalUntilNextTimeStamp = 0.0

                    // find closest timestamp to when we're waking up
                    var closest = 1000.0
                    var closestTime = 0.0
                    var closestTimeValue: NSValue = NSValue(time: CMTime.zero)

                    for time in times {
                        let ts = (time as! CMTime).seconds
                        let distance = abs(ts - player.currentTime().seconds)
                        if distance < closest {
                            closest = distance
                            closestTime = ts
                            closestTimeValue = time
                        }
                    }

                    // We also need the next timeStamp
                    let index = times.firstIndex(of: closestTimeValue)
                    if index! < times.count - 1 {
                        isLastTimeStamp = false
                        intervalUntilNextTimeStamp = (times[index!+1] as! CMTime).seconds - closestTime - 1
                    } else if video.duration > 0 {
                        isLastTimeStamp = true
                        // If we have a duration for the video, we may not !
                        intervalUntilNextTimeStamp = video.duration - closestTime - 1
                    }

                    // Animate text
                    var fadeAnimation: CAKeyframeAnimation

                    if preferences.showDescriptionsMode == Preferences.DescriptionMode.fade10seconds.rawValue {
                        fadeAnimation = self.createFadeInOutAnimation(duration: 11)
                    } else {
                        if isLastTimeStamp, video.duration == 0 {
                            // We have no idea when the video ends, so 2 minutes it is
                            fadeAnimation = self.createFadeInOutAnimation(duration: 120)
                        } else {
                            fadeAnimation = self.createFadeInOutAnimation(duration: intervalUntilNextTimeStamp)
                        }
                    }
                    // Get the string for the current timestamp
                    let key = String(format: "%.0f", closestTime)
                    let str = poiStringProvider.getString(key: keys[key]!, video: video)
                    self.setupTextLayer(view: view, string: str, duration: fadeAnimation.duration, isInitial: false, totalDuration: video.duration-1)

                    view.textLayer.add(fadeAnimation, forKey: "textfade")
                }
            } else {
                // We don't have any extended description, using Secondary name (location) or video name (City)
                let str: String
                if video.secondaryName != "" {
                    str = video.secondaryName
                } else {
                    str = video.name
                }
                var fadeAnimation: CAKeyframeAnimation

                if preferences.showDescriptionsMode == Preferences.DescriptionMode.fade10seconds.rawValue {
                    fadeAnimation = createFadeInOutAnimation(duration: 11)
                } else {
                    // Always show mode, use known video duration or some hardcoded duration
                    if video.duration > 0 {
                        fadeAnimation = createFadeInOutAnimation(duration: video.duration - 1)
                    } else {
                        // We should have the duration, if we don't, hardcode the longest known duration
                        fadeAnimation = createFadeInOutAnimation(duration: 807)
                    }
                }
                view.textLayer.add(fadeAnimation, forKey: "textfade")
                setupTextLayer(view: view, string: str, duration: fadeAnimation.duration, isInitial: true, totalDuration: video.duration)
            }
        }
    }

    func setupTextLayer(view: AerialView, string: String, duration: CFTimeInterval, isInitial: Bool, totalDuration: Double) {
        // Setup string
        view.textLayer.string = string
        view.textLayer.isWrapped = true
        let preferences = Preferences.sharedInstance

        // We override font size on previews
        var fontSize = CGFloat(preferences.fontSize!)
        if layer!.bounds.height < 200 {
            fontSize = 12
        }

        // We get the horizontal margin
        var mx = CGFloat(preferences.marginX!)

        if !preferences.overrideMargins {
            mx = 50
        }
        if isPreview {
            mx = 10
        }
        let boundingRect = CGSize(width: layer!.visibleRect.size.width-2*mx, height: layer!.visibleRect.size.height)

        // Get font with a fallback in case
        var font = NSFont(name: "Helvetica Neue Medium", size: 28)
        if let tryFont = NSFont(name: preferences.fontName!, size: fontSize) {
            font = tryFont
        }

        // Make sure we change the layer font/size
        view.textLayer.font = font
        view.textLayer.fontSize = fontSize

        let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font as Any]

        // Calculate bounding box
        let str = NSAttributedString(string: string, attributes: attributes)

        var rect = str.boundingRect(with: boundingRect, options: [.truncatesLastVisibleLine, .usesLineFragmentOrigin])
        // Last line won't appear if we don't adjust
        rect = CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.width, height: rect.height + 10)

        // Rebind frame
        view.textLayer.frame = rect

        // At the position the user wants
        if preferences.descriptionCorner == Preferences.DescriptionCorner.random.rawValue {
            // Randomish, we still want something different
            var corner = Int.random(in: 0...3)
            while corner == lastCorner {
                corner = Int.random(in: 0...3)
            }
            lastCorner = corner

            repositionTextLayer(view: view, position: corner)
            setupAndRepositionExtra(view: view, position: corner, duration: duration, isInitial: isInitial, totalDuration: totalDuration)
        } else {
            repositionTextLayer(view: view, position: preferences.descriptionCorner!)   // Or set position from pref
            setupAndRepositionExtra(view: view, position: preferences.descriptionCorner!,
                                    duration: duration, isInitial: isInitial, totalDuration: totalDuration)
        }
    }

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

    // swiftlint:disable:next cyclomatic_complexity
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
    }

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
