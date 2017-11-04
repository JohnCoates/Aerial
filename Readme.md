![screencast](https://cloud.githubusercontent.com/assets/499192/10754100/c0e1cc4c-7c95-11e5-9d3b-842d3acc2fd5.gif)

## Aerial - Apple TV Aerial Views Screen Saver
Aerial is a Mac screen saver based on the new Apple TV screen saver that displays the aerial movies Apple shot over New York, San Francisco, Hawaii, China, etc.

Aerial is completely open source, so feel free to contribute to its development!  

[![Github All Releases](https://img.shields.io/github/downloads/johncoates/aerial/total.svg?maxAge=86400)]()
[![GitHub contributors](https://img.shields.io/github/contributors/johncoates/aerial.svg?maxAge=2592000)]()
[![Build Status](https://travis-ci.org/JohnCoates/Aerial.svg?branch=master)](https://travis-ci.org/JohnCoates/Aerial)
[![codebeat badge](https://codebeat.co/badges/cefd1672-5501-4b79-8d08-c2121cdbc9ed)](https://codebeat.co/projects/github-com-johncoates-aerial-e1c8873e-7a9f-4c74-9e50-0380add2478a)
[![Code Climate](https://codeclimate.com/github/JohnCoates/Aerial/badges/gpa.svg)](https://codeclimate.com/github/JohnCoates/Aerial)
[![codecov](https://codecov.io/gh/JohnCoates/Aerial/branch/master/graph/badge.svg)](https://codecov.io/gh/JohnCoates/Aerial)

###### Windows user? Try [cDima/Aerial](https://github.com/cDima/Aerial/)
###### Linux user? Try [graysky2/xscreensaver-aerial](https://github.com/graysky2/xscreensaver-aerial/)

#### Coded with Love by John Coates

[![Twitter](http://i.imgur.com/KzOiue1.png)](https://twitter.com/JohnCoatesDev)
[![Email](http://i.imgur.com/FvDZudR.png)](mailto:john@johncoates.me)

## Installation

1. [Click here to Download](https://github.com/JohnCoates/Aerial/releases/download/v1.2/Aerial.zip)
2. Unzip the downloaded file.
3. Open **Aerial.saver** and confirm installation.

If Aerial.saver could not be opened, place Aerial.saver in ~/Library/Screen Savers

## Setting Aerial as Your Screen Saver

1. Open System Preferences -> Desktop & Screen Saver -> Screen Saver
2. Choose Aerial and click on Screen Saver Options to select your settings.

![Screenshot](https://cloud.githubusercontent.com/assets/499192/10754102/c58cc076-7c95-11e5-9579-4275740ba339.png)

## Uninstallation

There are three options to uninstall Aerial from your Mac.

* Right-click on the Aerial screen saver in System Preferences and select `Delete "Aerial"`.
* Or delete the file(s) directly. macOS can store screen savers in two locations. `/Library/Screen Savers` and `/Users/YOURUSERNAME/Library/Screen Savers`. Check both locations for a file called "Aerial.saver" and delete any copies you find.
* If you installed Aerial using brew, then the following command in a Terminal window should remove the brew installed version. `brew cask uninstall aerial`

You may also want to delete the folder `/Users/YOURUSERNAME/Library/Caches/Aerial`. This is where Aerial stores the cached copies of the aerial videos.

## Features
* **Auto Load Latest Aerials:** Aerials are loaded directly from Apple, so you're never out of date.
* **Play Different Aerial On Each Display:** If you've got multiple monitors, this setting loads a different aerial for each of your displays.
* **Favorites:** You can choose to only have certain aerials play.
* **Preview:** Clicking on an aerial in the screen saver options previews that aerial for you.

## Compatibility
Aerial is written in Swift, which requires OS X Mavericks or above.

## Community
- **Found a bug?** [Open an issue](https://github.com/JohnCoates/Aerial/issues/new). Try to be as specific as possible.
- **Have a feature request?** [Open an issue](https://github.com/JohnCoates/Aerial/issues/new). Tell me why this feature would be useful, and why you and others would want it.

## Contribute
I appreciate all pull requests.

## Brew Cask Support - Install Remotely
If you're looking to install Aerial across many systems, remotely, or simply from terminal I recommend [Brew Cask](http://caskroom.io/).

Issue the following terminal command: `brew cask install aerial`

## Troubleshooting

- Black screen: If you are behind a firewall (like Little Snitch or Hands Off!) try creating exceptions for Aerial to allow it access to Apple's servers. Be sure the applications 'ScreenSaverEngine.app' and 'System Preferences.app' are not being blocked access to *.phobos.apple.com and *.phobos.apple.com.edgesuite.net. If that isn't an option and you are on a Macbook try caching the videos while connected to a different network.
- "You cannot use the Aerial screen saver with this version of macOS." error: Select Aerial, close System Preferences with Aerial still selected, re-open System Preferences and Aerial should now work. This is a known bug with Swift screensavers in macOS/OS X reported to Apple as [rdar://25569037](http://www.openradar.me/25569037).

## License
[MIT License](https://raw.githubusercontent.com/JohnCoates/Aerial/master/LICENSE)
