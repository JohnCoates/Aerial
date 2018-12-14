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
        case cacheAerials = "cacheAerials"
        case customCacheDirectory = "cacheDirectory"
        case videoFormat = "videoFormat"
        case showDescriptions = "showDescriptions"
        case useCommunityDescriptions = "useCommunityDescriptions"
        case showDescriptionsMode = "showDescriptionsMode"
        case neverStreamVideos = "neverStreamVideos"
        case neverStreamPreviews = "neverStreamPreviews"
        case localizeDescriptions = "localizeDescriptions"
        case timeMode = "timeMode"
        case manualSunrise = "manualSunrise"
        case manualSunset = "manualSunset"
        case fadeMode = "fadeMode"
        case fadeModeText = "fadeModeText"
        case descriptionCorner = "descriptionCorner"
        case fontName = "fontName"
        case fontSize = "fontSize"
        case showClock = "showClock"
        case withSeconds = "withSeconds"
        case showMessage = "showMessage"
        case showMessageString = "showMessageString"
        case extraFontName = "extraFontName"
        case extraFontSize = "extraFontSize"
        case extraCorner = "extraCorner"
        case debugMode = "debugMode"
        case logToDisk = "logToDisk"
        case versionCheck = "versionCheck"
        case alsoVersionCheckBeta = "alsoVersionCheckBeta"
        case latitude = "latitude"
        case longitude = "longitude"

        case dimBrightness = "dimBrightness"
        case startDim = "startDim"
        case endDim = "endDim"
        case dimOnlyAtNight = "dimOnlyAtNight"
        case dimOnlyOnBattery = "dimOnlyOnBattery"
        case dimInMinutes = "dimInMinutes"
        case overrideDimInMinutes = "overrideDimInMinutes"
        case solarMode = "solarMode"

        case overrideMargins = "overrideMargins"
        case marginX = "marginX"
        case marginY = "marginY"

        case alternateVideoFormat = "alternateVideoFormat"
        case overrideOnBattery = "overrideOnBattery"
        case powerSavingOnLowBattery = "powerSavingOnLowBattery"

        case darkModeNightOverride = "darkModeNightOverride"
        case newVideosMode = "newVideosMode"
        case lastVideoCheck = "lastVideoCheck"
    }

    enum NewVideosMode: Int {
        case weekly, monthly, never
    }

    enum SolarMode: Int {
        case strict, official, civil, nautical, astronomical
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

    enum FadeMode: Int {
        // swiftlint:disable:next identifier_name
        case disabled, t0_5, t1, t2
    }

    enum MultiMonitorMode: Int {
        case mainOnly, mirrored, independant
    }

    enum TimeMode: Int {
        case disabled, nightShift, manual, lightDarkMode, coordinates
    }

    enum VideoFormat: Int {
        case v1080pH264, v1080pHEVC, v4KHEVC
    }

    enum AlternateVideoFormat: Int {
        case powerSaving, v1080pH264, v1080pHEVC, v4KHEVC
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
        defaultValues[.cacheAerials] = true
        defaultValues[.videoFormat] = VideoFormat.v1080pH264
        defaultValues[.showDescriptions] = true
        defaultValues[.useCommunityDescriptions] = true
        defaultValues[.showDescriptionsMode] = DescriptionMode.fade10seconds
        defaultValues[.neverStreamVideos] = false
        defaultValues[.neverStreamPreviews] = false
        defaultValues[.localizeDescriptions] = false
        defaultValues[.timeMode] = TimeMode.disabled
        defaultValues[.manualSunrise] = "09:00"
        defaultValues[.manualSunset] = "19:00"
        defaultValues[.multiMonitorMode] = MultiMonitorMode.mainOnly
        defaultValues[.fadeMode] = FadeMode.t1
        defaultValues[.fadeModeText] = FadeMode.t1
        defaultValues[.descriptionCorner] = DescriptionCorner.bottomLeft
        defaultValues[.fontName] = "Helvetica Neue Medium"
        defaultValues[.fontSize] = 28
        defaultValues[.showClock] = false
        defaultValues[.withSeconds] = false
        defaultValues[.showMessage] = false
        defaultValues[.showMessageString] = ""
        defaultValues[.extraFontName] = "Monaco"
        defaultValues[.extraFontSize] = 28
        defaultValues[.extraCorner] = ExtraCorner.same
        defaultValues[.debugMode] = false
        defaultValues[.logToDisk] = false
        defaultValues[.versionCheck] = VersionCheck.weekly
        defaultValues[.alsoVersionCheckBeta] = false
        defaultValues[.latitude] = ""
        defaultValues[.longitude] = ""
        defaultValues[.dimBrightness] = false
        defaultValues[.startDim] = 0.5
        defaultValues[.endDim] = 0.0
        defaultValues[.dimOnlyAtNight] = false
        defaultValues[.dimOnlyOnBattery] = false
        defaultValues[.dimInMinutes] = 30
        defaultValues[.overrideDimInMinutes] = false
        defaultValues[.solarMode] = SolarMode.official
        defaultValues[.overrideMargins] = false
        defaultValues[.marginX] = 50
        defaultValues[.marginY] = 50
        defaultValues[.overrideOnBattery] = false
        defaultValues[.powerSavingOnLowBattery] = false
        defaultValues[.alternateVideoFormat] = AlternateVideoFormat.powerSaving
        defaultValues[.darkModeNightOverride] = false
        defaultValues[.newVideosMode] = NewVideosMode.weekly

        // Set today's date as default
        let dateFormatter = DateFormatter()
        let current = Date()
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
    var lastVideoCheck: String? {
        get {
            return optionalValue(forIdentifier: .lastVideoCheck)
        }
        set {
            setValue(forIdentifier: .lastVideoCheck, value: newValue)
        }
    }

    var newVideosMode: Int? {
        get {
            return optionalValue(forIdentifier: .newVideosMode)
        }
        set {
            setValue(forIdentifier: .newVideosMode, value: newValue)
        }
    }

    var alternateVideoFormat: Int? {
        get {
            return optionalValue(forIdentifier: .alternateVideoFormat)
        }
        set {
            setValue(forIdentifier: .alternateVideoFormat, value: newValue)
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

    var darkModeNightOverride: Bool {
        get {
            return value(forIdentifier: .darkModeNightOverride)
        }
        set {
            setValue(forIdentifier: .darkModeNightOverride, value: newValue)
        }
    }

    var overrideOnBattery: Bool {
        get {
            return value(forIdentifier: .overrideOnBattery)
        }
        set {
            setValue(forIdentifier: .overrideOnBattery, value: newValue)
        }
    }

    var powerSavingOnLowBattery: Bool {
        get {
            return value(forIdentifier: .powerSavingOnLowBattery)
        }
        set {
            setValue(forIdentifier: .powerSavingOnLowBattery, value: newValue)
        }
    }

    var useCommunityDescriptions: Bool {
        get {
            return value(forIdentifier: .useCommunityDescriptions)
        }
        set {
            setValue(forIdentifier: .useCommunityDescriptions, value: newValue)
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

    var overrideMargins: Bool {
        get {
            return value(forIdentifier: .overrideMargins)
        }
        set {
            setValue(forIdentifier: .overrideMargins, value: newValue)
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

    var marginX: Int? {
        get {
            return optionalValue(forIdentifier: .marginX)
        }
        set {
            setValue(forIdentifier: .marginX, value: newValue)
        }
    }

    var marginY: Int? {
        get {
            return optionalValue(forIdentifier: .marginY)
        }
        set {
            setValue(forIdentifier: .marginY, value: newValue)
        }
    }

    var solarMode: Int? {
        get {
            return optionalValue(forIdentifier: .solarMode)
        }
        set {
            setValue(forIdentifier: .solarMode, value: newValue)
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

    var logToDisk: Bool {
        get {
            return value(forIdentifier: .logToDisk)
        }
        set {
            setValue(forIdentifier: .logToDisk, value: newValue)
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

    var showClock: Bool {
        get {
            return value(forIdentifier: .showClock)
        }
        set {
            setValue(forIdentifier: .showClock, value: newValue)
        }
    }

    var withSeconds: Bool {
        get {
            return value(forIdentifier: .withSeconds)
        }
        set {
            setValue(forIdentifier: .withSeconds, value: newValue)
        }
    }

    var showMessage: Bool {
        get {
            return value(forIdentifier: .showMessage)
        }
        set {
            setValue(forIdentifier: .showMessage, value: newValue)
        }
    }

    var latitude: String? {
        get {
            return optionalValue(forIdentifier: .latitude)
        }
        set {
            setValue(forIdentifier: .latitude, value: newValue)
        }
    }

    var longitude: String? {
        get {
            return optionalValue(forIdentifier: .longitude)
        }
        set {
            setValue(forIdentifier: .longitude, value: newValue)
        }
    }

    var showMessageString: String? {
        get {
            return optionalValue(forIdentifier: .showMessageString)
        }
        set {
            setValue(forIdentifier: .showMessageString, value: newValue)
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

    var cacheAerials: Bool {
        get {
            return value(forIdentifier: .cacheAerials)
        }
        set {
            setValue(forIdentifier: .cacheAerials, value: newValue)
        }
    }

    var neverStreamVideos: Bool {
        get {
            return value(forIdentifier: .neverStreamVideos)
        }
        set {
            setValue(forIdentifier: .neverStreamVideos, value: newValue)
        }
    }

    var neverStreamPreviews: Bool {
        get {
            return value(forIdentifier: .neverStreamPreviews)
        }
        set {
            setValue(forIdentifier: .neverStreamPreviews, value: newValue)
        }
    }

    var localizeDescriptions: Bool {
        get {
            return value(forIdentifier: .localizeDescriptions)
        }
        set {
            setValue(forIdentifier: .localizeDescriptions, value: newValue)
        }
    }

    var fontName: String? {
        get {
            return optionalValue(forIdentifier: .fontName)
        }
        set {
            setValue(forIdentifier: .fontName, value: newValue)
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

    var fontSize: Double? {
        get {
            return optionalValue(forIdentifier: .fontSize)
        }
        set {
            setValue(forIdentifier: .fontSize, value: newValue)
        }

    }

    var extraFontName: String? {
        get {
            return optionalValue(forIdentifier: .extraFontName)
        }
        set {
            setValue(forIdentifier: .extraFontName, value: newValue)
        }
    }

    var extraFontSize: Double? {
        get {
            return optionalValue(forIdentifier: .extraFontSize)
        }
        set {
            setValue(forIdentifier: .extraFontSize, value: newValue)
        }

    }
    var manualSunrise: String? {
        get {
            return optionalValue(forIdentifier: .manualSunrise)
        }
        set {
            setValue(forIdentifier: .manualSunrise, value: newValue)
        }
    }

    var manualSunset: String? {
        get {
            return optionalValue(forIdentifier: .manualSunset)
        }
        set {
            setValue(forIdentifier: .manualSunset, value: newValue)
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

    var extraCorner: Int? {
        get {
            return optionalValue(forIdentifier: .extraCorner)
        }
        set {
            setValue(forIdentifier: .extraCorner, value: newValue)
        }
    }

    var fadeMode: Int? {
        get {
            return optionalValue(forIdentifier: .fadeMode)
        }
        set {
            setValue(forIdentifier: .fadeMode, value: newValue)
        }
    }

    var fadeModeText: Int? {
        get {
            return optionalValue(forIdentifier: .fadeModeText)
        }
        set {
            setValue(forIdentifier: .fadeModeText, value: newValue)
        }
    }

    var timeMode: Int? {
        get {
            return optionalValue(forIdentifier: .timeMode)
        }
        set {
            setValue(forIdentifier: .timeMode, value: newValue)
        }
    }

    var videoFormat: Int? {
        get {
            return optionalValue(forIdentifier: .videoFormat)
        }
        set {
            setValue(forIdentifier: .videoFormat, value: newValue)
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
} //swiftlint:disable:this file_length
