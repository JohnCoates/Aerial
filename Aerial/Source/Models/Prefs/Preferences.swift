//
//  Preferences.swift
//  Aerial
//
//  Created by John Coates on 9/21/16.
//  Copyright © 2016 John Coates. All rights reserved.
//

import Foundation
import ScreenSaver

// swiftlint:disable:next type_body_length
final class Preferences {

    // MARK: - Types

    fileprivate enum Identifiers: String {
        case differentAerialsOnEachDisplay = "differentAerialsOnEachDisplay"
        case multiMonitorMode = "multiMonitorMode"
        case customCacheDirectory = "cacheDirectory"
        case showDescriptions = "showDescriptions"
        case showDescriptionsMode = "showDescriptionsMode"
        case descriptionCorner = "descriptionCorner"

        case debugMode = "debugMode"
        case versionCheck = "versionCheck"
        case alsoVersionCheckBeta = "alsoVersionCheckBeta"

        case dimBrightness = "dimBrightness"
        case startDim = "startDim"
        case endDim = "endDim"
        case dimOnlyAtNight = "dimOnlyAtNight"
        case dimOnlyOnBattery = "dimOnlyOnBattery"
        case dimInMinutes = "dimInMinutes"
        case overrideDimInMinutes = "overrideDimInMinutes"
        case lastVideoCheck = "lastVideoCheck"

        case ciOverrideLanguage = "ciOverrideLanguage"
        case videoSets = "videoSets"

        case updateWhileSaverMode = "updateWhileSaverMode"
        case allowBetas = "allowBetas"
        case betaCheckFrequency = "betaCheckFrequency"

        case newDisplayDict = "newDisplayDict"
        case logMilliseconds = "logMilliseconds"
    }

    enum BetaCheckFrequency: Int {
        case hourly, bidaily, daily
    }

    enum VersionCheck: Int {
        case never, daily, weekly, monthly
    }

    enum ExtraCorner: Int {
        case same, hOpposed, dOpposed
    }

    enum DescriptionCorner: Int {
        case topLeft, topRight, bottomLeft, bottomRight, random
    }

    enum MultiMonitorMode: Int {
        case mainOnly, mirrored, independant, secondaryOnly
    }

    enum DescriptionMode: Int {
        case fade10seconds, always
    }

    static let sharedInstance = Preferences()

    lazy var userDefaults: UserDefaults = {
        let module = "com.JohnCoates.Aerial"

        guard let userDefaults = ScreenSaverDefaults(forModuleWithName: module) else {
            warnLog("Couldn't create ScreenSaverDefaults, creating generic UserDefaults")
            return UserDefaults()
        }

        return userDefaults
    }()

    // MARK: - Setup

    init() {
        registerDefaultValues()
    }

    func registerDefaultValues() {
        var defaultValues = [Identifiers: Any]()
        defaultValues[.differentAerialsOnEachDisplay] = false
        defaultValues[.showDescriptions] = true
        defaultValues[.showDescriptionsMode] = DescriptionMode.fade10seconds
        defaultValues[.multiMonitorMode] = MultiMonitorMode.mainOnly
        defaultValues[.descriptionCorner] = DescriptionCorner.bottomLeft
        defaultValues[.debugMode] = true
        defaultValues[.versionCheck] = VersionCheck.weekly
        defaultValues[.alsoVersionCheckBeta] = false
        defaultValues[.dimBrightness] = false
        defaultValues[.startDim] = 0.5
        defaultValues[.endDim] = 0.0
        defaultValues[.dimOnlyAtNight] = false
        defaultValues[.dimOnlyOnBattery] = false
        defaultValues[.dimInMinutes] = 30
        defaultValues[.overrideDimInMinutes] = false
        defaultValues[.ciOverrideLanguage] = ""
        defaultValues[.videoSets] = [String: [String]]()
        defaultValues[.updateWhileSaverMode] = true
        defaultValues[.allowBetas] = false
        defaultValues[.betaCheckFrequency] = BetaCheckFrequency.daily
        defaultValues[.newDisplayDict] = [String: Bool]()
        defaultValues[.logMilliseconds] = false

        // Set today's date as default
        let dateFormatter = DateFormatter()
        let current = Date(timeIntervalSinceReferenceDate: -123456789.0)
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: current)
        defaultValues[.lastVideoCheck] = today

        let defaults = defaultValues.reduce([String: Any]()) { (result, pair:(key: Identifiers, value: Any)) -> [String: Any] in
            var mutable = result
            mutable[pair.key.rawValue] = pair.value
            return mutable
        }

        userDefaults.register(defaults: defaults)
    }

    // MARK: - Variables
    var videoSets: [String: [String]] {
        get {
            return userDefaults.dictionary(forKey: "videoSets") as! [String: [String]]
        }
        set {
            setValue(forIdentifier: .videoSets, value: newValue)
        }
    }

    var newDisplayDict: [String: Bool] {
        get {
            return userDefaults.dictionary(forKey: "newDisplayDict") as! [String: Bool]
        }
        set {
            setValue(forIdentifier: .newDisplayDict, value: newValue)
        }
    }

    var lastVideoCheck: String? {
        get {
            return optionalValue(forIdentifier: .lastVideoCheck)
        }
        set {
            setValue(forIdentifier: .lastVideoCheck, value: newValue)
        }
    }

    var betaCheckFrequency: Int? {
        get {
            return optionalValue(forIdentifier: .betaCheckFrequency)
        }
        set {
            setValue(forIdentifier: .betaCheckFrequency, value: newValue)
        }
    }

    var logMilliseconds: Bool {
        get {
            return value(forIdentifier: .logMilliseconds)
        }
        set {
            setValue(forIdentifier: .logMilliseconds, value: newValue)
        }
    }

    var allowBetas: Bool {
        get {
            return value(forIdentifier: .allowBetas)
        }
        set {
            setValue(forIdentifier: .allowBetas, value: newValue)
        }
    }

    var updateWhileSaverMode: Bool {
        get {
            return value(forIdentifier: .updateWhileSaverMode)
        }
        set {
            setValue(forIdentifier: .updateWhileSaverMode, value: newValue)
        }
    }

    var overrideDimInMinutes: Bool {
        get {
            return value(forIdentifier: .overrideDimInMinutes)
        }
        set {
            setValue(forIdentifier: .overrideDimInMinutes, value: newValue)
        }
    }

    var dimBrightness: Bool {
        get {
            return value(forIdentifier: .dimBrightness)
        }
        set {
            setValue(forIdentifier: .dimBrightness, value: newValue)
        }
    }

    var dimOnlyAtNight: Bool {
        get {
            return value(forIdentifier: .dimOnlyAtNight)
        }
        set {
            setValue(forIdentifier: .dimOnlyAtNight, value: newValue)
        }
    }

    var dimOnlyOnBattery: Bool {
        get {
            return value(forIdentifier: .dimOnlyOnBattery)
        }
        set {
            setValue(forIdentifier: .dimOnlyOnBattery, value: newValue)
        }
    }

    var dimInMinutes: Int? {
        get {
            return optionalValue(forIdentifier: .dimInMinutes)
        }
        set {
            setValue(forIdentifier: .dimInMinutes, value: newValue)
        }
    }

    var debugMode: Bool {
        get {
            return value(forIdentifier: .debugMode)
        }
        set {
            setValue(forIdentifier: .debugMode, value: newValue)
        }
    }

    var alsoVersionCheckBeta: Bool {
        get {
            return value(forIdentifier: .alsoVersionCheckBeta)
        }
        set {
            setValue(forIdentifier: .alsoVersionCheckBeta, value: newValue)
        }
    }

    var ciOverrideLanguage: String? {
        get {
            return optionalValue(forIdentifier: .ciOverrideLanguage)
        }
        set {
            setValue(forIdentifier: .ciOverrideLanguage, value: newValue)
        }
    }

    var differentAerialsOnEachDisplay: Bool {
        get {
            return value(forIdentifier: .differentAerialsOnEachDisplay)
        }
        set {
            setValue(forIdentifier: .differentAerialsOnEachDisplay, value: newValue)
        }
    }

    var startDim: Double? {
        get {
            return optionalValue(forIdentifier: .startDim)
        }
        set {
            setValue(forIdentifier: .startDim, value: newValue)
        }
    }

    var endDim: Double? {
        get {
            return optionalValue(forIdentifier: .endDim)
        }
        set {
            setValue(forIdentifier: .endDim, value: newValue)
        }
    }

    var customCacheDirectory: String? {
        get {
            return optionalValue(forIdentifier: .customCacheDirectory)
        }
        set {
            setValue(forIdentifier: .customCacheDirectory, value: newValue)
        }
    }

    var versionCheck: Int? {
        get {
            return optionalValue(forIdentifier: .versionCheck)
        }
        set {
            setValue(forIdentifier: .versionCheck, value: newValue)
        }
    }

    var descriptionCorner: Int? {
        get {
            return optionalValue(forIdentifier: .descriptionCorner)
        }
        set {
            setValue(forIdentifier: .descriptionCorner, value: newValue)
        }
    }

    var showDescriptionsMode: Int? {
        get {
            return optionalValue(forIdentifier: .showDescriptionsMode)
        }
        set {
            setValue(forIdentifier: .showDescriptionsMode, value: newValue)
        }
    }

    var multiMonitorMode: Int? {
        get {
            return optionalValue(forIdentifier: .multiMonitorMode)
        }
        set {
            setValue(forIdentifier: .multiMonitorMode, value: newValue)
        }
    }

    var showDescriptions: Bool {
        get {
            return value(forIdentifier: .showDescriptions)
        }
        set {
            setValue(forIdentifier: .showDescriptions,
                     value: newValue)
        }
    }

    func videoIsInRotation(videoID: String) -> Bool {
        let key = "remove\(videoID)"
        let removed = userDefaults.bool(forKey: key)
        return !removed
    }

    func setVideo(videoID: String, inRotation: Bool,
                  synchronize: Bool = true) {
        let key = "remove\(videoID)"
        let removed = !inRotation
        userDefaults.set(removed, forKey: key)

        if synchronize {
            self.synchronize()
        }
    }

    // MARK: - Setting, Getting

    fileprivate func value(forIdentifier identifier: Identifiers) -> Bool {
        let key = identifier.rawValue
        return userDefaults.bool(forKey: key)
    }

    fileprivate func optionalValue(forIdentifier identifier: Identifiers) -> String? {
        let key = identifier.rawValue
        return userDefaults.string(forKey: key)
    }

    fileprivate func optionalValue(forIdentifier identifier: Identifiers) -> Int? {
        let key = identifier.rawValue
        return userDefaults.integer(forKey: key)
    }

    fileprivate func optionalValue(forIdentifier identifier: Identifiers) -> Double? {
        let key = identifier.rawValue
        return userDefaults.double(forKey: key)
    }

    fileprivate func setValue(forIdentifier identifier: Identifiers, value: Any?) {
        let key = identifier.rawValue
        if value == nil {
            userDefaults.removeObject(forKey: key)
        } else {
            userDefaults.set(value, forKey: key)
        }
        synchronize()
    }

    func synchronize() {
        userDefaults.synchronize()
    }
}
