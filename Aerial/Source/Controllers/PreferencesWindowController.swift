//
//  PreferencesWindowController.swift
//  Aerial
//
//  Created by John Coates on 10/23/15.
//  Copyright © 2015 John Coates. All rights reserved.
//

import Cocoa
import AVKit
import AVFoundation
import ScreenSaver
import CoreLocation
import Sparkle

@objc(PreferencesWindowController)
// swiftlint:disable:next type_body_length
final class PreferencesWindowController: NSWindowController, NSOutlineViewDataSource, NSOutlineViewDelegate {

    lazy var customVideosController: CustomVideoController = CustomVideoController()

    // Main UI
    @IBOutlet weak var prefTabView: NSTabView!
    @IBOutlet weak var downloadProgressIndicator: NSProgressIndicator!
    @IBOutlet weak var downloadStopButton: NSButton!
    @IBOutlet var versionButton: NSButton!
    @IBOutlet var closeButton: NSButton!

    // Popovers
    @IBOutlet var popover: NSPopover!
    @IBOutlet var popoverH264Indicator: NSButton!
    @IBOutlet var popoverHEVCIndicator: NSButton!
    @IBOutlet var popoverH264Label: NSTextField!
    @IBOutlet var popoverHEVCLabel: NSTextField!
    @IBOutlet var secondProjectPageLink: NSButton!

    @IBOutlet var popoverHDR: NSPopover!

    @IBOutlet var popoverTime: NSPopover!
    @IBOutlet var linkTimeWikipediaButton: NSButton!

    @IBOutlet var popoverPower: NSPopover!
    @IBOutlet var popoverUpdate: NSPopover!

    // Videos tab
    @IBOutlet var outlineView: NSOutlineView!
    @IBOutlet var outlineViewSettings: NSButton!

    @IBOutlet var videoMenu: NSMenu!
    @IBOutlet var rightClickOpenQuickTimeMenuItem: NSMenuItem!
    @IBOutlet var rightClickDownloadVideoMenuItem: NSMenuItem!
    @IBOutlet var rightClickMoveToTrashMenuItem: NSMenuItem!

    @IBOutlet var videoSetsButton: NSButton!

    @IBOutlet var playerView: AVPlayerView!
    @IBOutlet var previewDisabledTextfield: NSTextField!

    @IBOutlet var fadeInOutModePopup: NSPopUpButton!
    @IBOutlet var popupVideoFormat: NSPopUpButton!
    @IBOutlet var useHDRCheckbox: NSButton!

    @IBOutlet var overrideOnBatteryCheckbox: NSButton!
    @IBOutlet var alternatePopupVideoFormat: NSPopUpButton!
    @IBOutlet var powerSavingOnLowBatteryCheckbox: NSButton!
    @IBOutlet var rightArrowKeyPlaysNextCheckbox: NSButton!
    @IBOutlet var synchronizedModeCheckbox: NSButton!
    @IBOutlet var projectPageLink: NSButton!

    // Displays tab
    @IBOutlet var displayInstructionLabel: NSTextField!
    @IBOutlet var newDisplayModePopup: NSPopUpButton!
    @IBOutlet var newViewingModePopup: NSPopUpButton!
    @IBOutlet var aspectModePopup: NSPopUpButton!

    @IBOutlet var displayMarginBox: NSBox!
    @IBOutlet var horizontalDisplayMarginTextfield: NSTextField!
    @IBOutlet var verticalDisplayMarginTextfield: NSTextField!

    @IBOutlet var displayMarginAdvancedMode: NSButton!

    @IBOutlet var displayMarginAdvancedEdit: NSButton!
    // Text tab
    @IBOutlet var showDescriptionsCheckbox: NSButton!
    @IBOutlet var descriptionModePopup: NSPopUpButton!
    @IBOutlet weak var fadeInOutTextModePopup: NSPopUpButton!
    @IBOutlet var localizeForTvOS12Checkbox: NSButton!
    @IBOutlet var currentLocaleLabel: NSTextField!
    @IBOutlet weak var useCommunityCheckbox: NSButton!
    @IBOutlet var ciOverrideLanguagePopup: NSPopUpButton!

    @IBOutlet var currentFontLabel: NSTextField!
    @IBOutlet var fontPickerButton: NSButton!
    @IBOutlet var fontResetButton: NSButton!

    @IBOutlet var changeCornerMargins: NSButton!
    @IBOutlet var marginHorizontalTextfield: NSTextField!
    @IBOutlet var marginVerticalTextfield: NSTextField!
    @IBOutlet var secondaryMarginHorizontalTextfield: NSTextField!
    @IBOutlet var secondaryMarginVerticalTextfield: NSTextField!
    @IBOutlet var editMarginButton: NSButton!
    @IBOutlet var editMarginsPanel: NSPanel!
    @IBOutlet var editExtraMessagePanel: NSPanel!

    @IBOutlet var cornerContainer: NSTextField!
    @IBOutlet var cornerTopLeft: NSButton!
    @IBOutlet var cornerTopRight: NSButton!
    @IBOutlet var cornerBottomLeft: NSButton!
    @IBOutlet var cornerBottomRight: NSButton!
    @IBOutlet var cornerRandom: NSButton!

    @IBOutlet weak var extraCornerPopup: NSPopUpButton!
    @IBOutlet var showClockCheckbox: NSButton!
    @IBOutlet weak var withSecondsCheckbox: NSButton!
    @IBOutlet var showExtraMessage: NSButton!
    @IBOutlet var extraMessageTextField: NSTextField!
    @IBOutlet var editExtraMessageButton: NSButton!
    @IBOutlet var secondaryExtraMessageTextField: NSTextField!
    @IBOutlet var extraMessageFontLabel: NSTextField!
    @IBOutlet var extraFontPickerButton: NSButton!
    @IBOutlet var extraFontResetButton: NSButton!

    // Time Tab
    @IBOutlet var iconTime1: NSImageCell!
    @IBOutlet var iconTime2: NSImageCell!
    @IBOutlet var iconTime3: NSImageCell!

    @IBOutlet var timeCalculateRadio: NSButton!
    @IBOutlet var latitudeTextField: NSTextField!
    @IBOutlet var latitudeFormatter: NumberFormatter!
    @IBOutlet var longitudeTextField: NSTextField!
    @IBOutlet var longitudeFormatter: NumberFormatter!
    @IBOutlet var findCoordinatesButton: NSButton!
    @IBOutlet var extraLatitudeTextField: NSTextField!
    @IBOutlet var extraLatitudeFormatter: NumberFormatter!
    @IBOutlet var extraLongitudeTextField: NSTextField!
    @IBOutlet var extraLongitudeFormatter: NumberFormatter!
    @IBOutlet var enterCoordinatesButton: NSButton!
    @IBOutlet var solarModePopup: NSPopUpButton!

    @IBOutlet var timeNightShiftRadio: NSButton!
    @IBOutlet var nightShiftLabel: NSTextField!

    @IBOutlet var timeManualRadio: NSButton!
    @IBOutlet var sunriseTime: NSDatePicker!
    @IBOutlet var sunsetTime: NSDatePicker!

    @IBOutlet var timeLightDarkModeRadio: NSButton!
    @IBOutlet var lightDarkModeLabel: NSTextField!

    @IBOutlet var timeDisabledRadio: NSButton!

    @IBOutlet var enterCoordinatesPanel: NSPanel!
    @IBOutlet var calculateCoordinatesLabel: NSTextField!

    @IBOutlet var overrideNightOnDarkMode: NSButton!

    // Brightness tab
    @IBOutlet var dimBrightness: NSButton!
    @IBOutlet var dimStartFrom: NSSlider!
    @IBOutlet var dimFadeTo: NSSlider!

    @IBOutlet var sleepAfterLabel: NSTextField!

    @IBOutlet var overrideDimFadeCheckbox: NSButton!
    @IBOutlet var dimFadeInMinutes: NSTextField!
    @IBOutlet var dimFadeInMinutesStepper: NSStepper!
    @IBOutlet var dimOnlyAtNight: NSButton!
    @IBOutlet var dimOnlyOnBattery: NSButton!

    // Caches tab
    @IBOutlet var cacheAerialsAsTheyPlayCheckbox: NSButton!
    @IBOutlet var neverStreamVideosCheckbox: NSButton!
    @IBOutlet var neverStreamPreviewsCheckbox: NSButton!
    @IBOutlet var cacheLocation: NSPathControl!
    @IBOutlet weak var downloadNowButton: NSButton!
    @IBOutlet weak var cacheSizeTextField: NSTextField!

    // Updates Tab
    @IBOutlet var newVideosModePopup: NSPopUpButton!
    @IBOutlet var checkNowButton: NSButton!
    @IBOutlet var lastCheckedVideosLabel: NSTextField!

    @IBOutlet var automaticallyCheckForUpdatesCheckbox: NSButton!
    @IBOutlet var allowScreenSaverModeUpdateCheckbox: NSButton!
    @IBOutlet var allowBetasCheckbox: NSButton!
    @IBOutlet var betaCheckFrequencyPopup: NSPopUpButton!
    @IBOutlet var lastCheckedSparkle: NSTextField!

    // Advanced Tab
    @IBOutlet weak var debugModeCheckbox: NSButton!
    @IBOutlet weak var showLogBottomClick: NSButton!
    @IBOutlet weak var logToDiskCheckbox: NSButton!
    @IBOutlet var logMillisecondsButton: NSButton!

    @IBOutlet var videoVersionsLabel: NSTextField!
    @IBOutlet var moveOldVideosButton: NSButton!
    @IBOutlet var trashOldVideosButton: NSButton!

    // Video sets panel
    @IBOutlet var addVideoSetPanel: NSPanel!
    @IBOutlet var addVideoSetTextField: NSTextField!
    @IBOutlet var addVideoSetConfirmButton: NSButton!
    @IBOutlet var addVideoSetCancelButton: NSButton!
    @IBOutlet var addVideoSetErrorLabel: NSTextField!

    // Log Panel
    @IBOutlet var logPanel: NSPanel!
    @IBOutlet weak var logTableView: NSTableView!

    // Quit confirmation Panel
    @IBOutlet var quitConfirmationPanel: NSPanel!

    // Change cache folder Panel
    @IBOutlet var changeCacheFolderPanel: NSPanel!
    @IBOutlet var cacheFolderTextField: NSTextField!

    @IBOutlet var displayMarginAdvancedPanel: NSPanel!
    @IBOutlet var displayMarginAdvancedTextfield: NSTextField!

    var player: AVPlayer = AVPlayer()

    var videos: [AerialVideo]?
    // cities -> time of day -> videos
    var cities = [City]()

    static var loadedJSON: Bool = false

    lazy var preferences = Preferences.sharedInstance

    let fontManager: NSFontManager
    var fontEditing = 0     // To track the font we are changing

    var highestLevel: ErrorLevel?  // To track the largest level of error received

    var savedBrightness: Float?

    var locationManager: CLLocationManager?
    var sparkleUpdater: SUUpdater?

    @IBOutlet var displayView: DisplayView!
    public var appMode: Bool = false

    lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }()

    required init?(coder decoder: NSCoder) {
        self.fontManager = NSFontManager.shared
        debugLog("pwc init1")
        super.init(coder: decoder)
    }

    // We start here from SysPref and App mode
    override init(window: NSWindow?) {
        self.fontManager = NSFontManager.shared
        debugLog("pwc init2")
        super.init(window: window)
    }

    // MARK: - Lifecycle
    // Before Sparkle tries to restart Aerial, we dismiss the sheet *and* quit System Preferences
    // This is required as killing Aerial will crash the preview outside of Aerial, in System Preferences
    @objc func sparkleWillRestart() {
        debugLog("Sparkle will restart, properly quitting")
        window?.sheetParent?.endSheet(window!)
        for app in NSWorkspace.shared.runningApplications where app.bundleIdentifier == "com.apple.systempreferences" {
            app.terminate()
        }
    }

    // sawiftlint:disable:next cyclomatic_complexity
    override func awakeFromNib() {
        super.awakeFromNib()

        // We register for the notification just before Sparkle tries to terminate Aerial
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.sparkleWillRestart),
            name: Notification.Name.SUUpdaterWillRestart,
            object: nil)

        // Starting the Sparkle update system
        sparkleUpdater = SUUpdater.init(for: Bundle(for: PreferencesWindowController.self))
        // We override the feeds for betas
        if preferences.allowBetas {
            sparkleUpdater?.feedURL = URL(string: "https://raw.githubusercontent.com/JohnCoates/Aerial/master/beta-appcast.xml")
        }

        // Setup the updates for the Logs
        let logger = Logger.sharedInstance
        logger.addCallback {level in
            self.updateLogs(level: level)
        }

        // Setup the updates for the download status
        let videoManager = VideoManager.sharedInstance
        videoManager.addCallback { done, total in
            self.updateDownloads(done: done, total: total, progress: 0)
        }
        videoManager.addProgressCallback { done, total, progress in
            self.updateDownloads(done: done, total: total, progress: progress)
        }

        loadJSON()  // Async loading

        logTableView.delegate = self
        logTableView.dataSource = self

        // Grab version from bundle
        if let version = Bundle(identifier: "com.johncoates.Aerial-Test")?.infoDictionary?["CFBundleShortVersionString"] as? String {
            versionButton.title = version
        } else if let version = Bundle(identifier: "com.JohnCoates.Aerial")?.infoDictionary?["CFBundleShortVersionString"] as? String {
            versionButton.title = version
        }
        debugLog("Aerial control panel V\(versionButton.title)")

        setupVideosTab()
        setupDisplaysTab()
        setupTextTab()
        setupTimeTab()
        setupBrightnessTab()
        setupCacheTab()
        setupUpdatesTab()
        setupAdvancedTab()

        colorizeProjectPageLinks()

        // To workaround our High Sierra issues with textfields, we have separate panels
        // that replicate the features and are editable. They are hidden unless needed.
        if #available(OSX 10.14, *) {
            editMarginButton.isHidden = true
            editExtraMessageButton.isHidden = true
            enterCoordinatesButton.isHidden = true
        } else {
            marginHorizontalTextfield.isEnabled = false
            marginVerticalTextfield.isEnabled = false
            extraMessageTextField.isEnabled = false
            latitudeTextField.isEnabled = false
            longitudeTextField.isEnabled = false
        }

        // We also load our CustomVideos nib here
        let bundle = Bundle(for: PreferencesWindowController.self)
        var topLevelObjects: NSArray? = NSArray()
        if !bundle.loadNibNamed(NSNib.Name("CustomVideos"),
                            owner: customVideosController,
                            topLevelObjects: &topLevelObjects) {
            errorLog("Could not load nib for CustomVideos, please report")
        }
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        // Workaround for garbled icons on non retina, we force redraw
        outlineView.reloadData()
        debugLog("wdl")
    }

    @IBAction func close(_ sender: AnyObject?) {
        // We ask for confirmation in case downloads are ongoing
        if !downloadProgressIndicator.isHidden {
            quitConfirmationPanel.makeKeyAndOrderFront(self)
        } else {
            // This seems needed for screensavers as our lifecycle is different from a regular app
            preferences.synchronize()
            logPanel.close()
            if appMode {
                NSApplication.shared.terminate(nil)
            } else {
                window?.sheetParent?.endSheet(window!)
            }
        }
    }

    @IBAction func confirmQuitClick(_ sender: Any) {
        quitConfirmationPanel.close()
        preferences.synchronize()
        logPanel.close()
        if appMode {
            NSApplication.shared.terminate(nil)
        } else {
            window?.sheetParent?.endSheet(window!)
        }
    }

    @IBAction func cancelQuitClick(_ sender: Any) {
        quitConfirmationPanel.close()
    }

    // MARK: - Setup

    fileprivate func colorizeProjectPageLinks() {
        let color = NSColor(calibratedRed: 0.18, green: 0.39, blue: 0.76, alpha: 1)
        var coloredLink = NSMutableAttributedString(attributedString: projectPageLink.attributedTitle)
        var fullRange = NSRange(location: 0, length: coloredLink.length)
        coloredLink.addAttribute(.foregroundColor, value: color, range: fullRange)
        projectPageLink.attributedTitle = coloredLink

        // We have an extra project link on the video format popover, color it too
        coloredLink = NSMutableAttributedString(attributedString: secondProjectPageLink.attributedTitle)
        fullRange = NSRange(location: 0, length: coloredLink.length)
        coloredLink.addAttribute(.foregroundColor, value: color, range: fullRange)
        secondProjectPageLink.attributedTitle = coloredLink

        // We have an extra project link on the video format popover, color it too
        coloredLink = NSMutableAttributedString(attributedString: linkTimeWikipediaButton.attributedTitle)
        fullRange = NSRange(location: 0, length: coloredLink.length)
        coloredLink.addAttribute(.foregroundColor, value: color, range: fullRange)
        linkTimeWikipediaButton.attributedTitle = coloredLink

        // We have an extra project link on the video format popover, color it too
        coloredLink = NSMutableAttributedString(attributedString: versionButton.attributedTitle)
        fullRange = NSRange(location: 0, length: coloredLink.length)
        coloredLink.addAttribute(.foregroundColor, value: color, range: fullRange)
        versionButton.attributedTitle = coloredLink

    }

    @IBAction func versionButtonClick(_ sender: Any) {
        let workspace = NSWorkspace.shared
        var url: URL

        if versionButton.title.contains("beta") {
            url = URL(string: "https://github.com/JohnCoates/Aerial/releases/tag/v" + versionButton.title)!
        } else {
            url = URL(string: "https://github.com/JohnCoates/Aerial/blob/master/Documentation/ChangeLog.md")!
        }

        workspace.open(url)
    }

    // MARK: - Links

    @IBAction func pageProjectClick(_ button: NSButton?) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "http://github.com/JohnCoates/Aerial")!
        workspace.open(url)
    }

    // MARK: - Manifest

    func loadJSON() {
        if PreferencesWindowController.loadedJSON {
            return
        }
        PreferencesWindowController.loadedJSON = true

        ManifestLoader.instance.addCallback { manifestVideos in
            self.loaded(manifestVideos: manifestVideos)
        }
    }

    func reloadJson() {
        ManifestLoader.instance.reloadFiles()
    }

    func loaded(manifestVideos: [AerialVideo]) {
        debugLog("Callback after manifest loading")
        var videos = [AerialVideo]()
        var cities = [String: City]()

        // Grab a fresh version, because our callback can be feeding us wrong data in CVC
        let freshManifestVideos = ManifestLoader.instance.loadedManifest
        //debugLog("freshManifestVideos count : \(freshManifestVideos.count)")

        // First day, then night
        for video in freshManifestVideos {
            let name = video.name

            if cities.keys.contains(name) == false {
                cities[name] = City(name: name)
            }
            let city = cities[name]!

            let timeOfDay = video.timeOfDay
            city.addVideoForTimeOfDay(timeOfDay, video: video)

            videos.append(video)
        }

        self.videos = videos

        // sort cities by name
        let unsortedCities = cities.values
        let sortedCities = unsortedCities.sorted { $0.name < $1.name }

        self.cities = sortedCities

        DispatchQueue.main.async {
            self.outlineView.reloadData()
            self.outlineView.expandItem(nil, expandChildren: true)
        }

        // We update the info in the advanced tab
        let (description, total) = ManifestLoader.instance.getOldFilesEstimation()
        videoVersionsLabel.stringValue = description
        if total > 0 {
            moveOldVideosButton.isEnabled = true
            trashOldVideosButton.isEnabled = true
        } else {
            moveOldVideosButton.isEnabled = false
            trashOldVideosButton.isEnabled = false
        }
    }
}
