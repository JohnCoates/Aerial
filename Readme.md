<p align="center">
  <img src="https://cloud.githubusercontent.com/assets/499192/10754100/c0e1cc4c-7c95-11e5-9d3b-842d3acc2fd5.gif">
</p>

# Aerial - Apple TV Aerial Views Screen Saver

Aerial is a Mac screensaver based on the new Apple TV screensaver that displays the Aerial movies Apple shot over New York, San Francisco, Hawaii, China, etc. Starting with version 1.4, this also includes the new ISS videos available in tvOS 12!

Aerial is completely open source, so feel free to contribute to its development.

![Github All Releases](https://img.shields.io/github/downloads/johncoates/aerial/total.svg?maxAge=86400)
![GitHub contributors](https://img.shields.io/github/contributors/johncoates/aerial.svg?maxAge=2592000)
[![Build Status](https://travis-ci.org/JohnCoates/Aerial.svg?branch=master)](https://travis-ci.org/JohnCoates/Aerial)
[![codebeat badge](https://codebeat.co/badges/cefd1672-5501-4b79-8d08-c2121cdbc9ed)](https://codebeat.co/projects/github-com-johncoates-aerial-e1c8873e-7a9f-4c74-9e50-0380add2478a)
[![Code Climate](https://codeclimate.com/github/JohnCoates/Aerial/badges/gpa.svg)](https://codeclimate.com/github/JohnCoates/Aerial)
[![codecov](https://codecov.io/gh/JohnCoates/Aerial/branch/master/graph/badge.svg)](https://codecov.io/gh/JohnCoates/Aerial)

###### Windows user? Try [cDima/Aerial](https://github.com/cDima/Aerial/) Linux user? Try [graysky2/xscreensaver-aerial](https://github.com/graysky2/xscreensaver-aerial/)

Aerial was started in 2015 by John Coates ([Twitter](https://twitter.com/JohnCoatesDev), [Email](mailto:john@johncoates.me))

Starting with version 1.4, Aerial is also maintained by [Guillaume Louel](https://github.com/glouel) ([Twitter](https://twitter.com/C_Wiz), [PayPal](https://paypal.me/glouel?locale.x=fr_FR)).

You can see a list of contributors [here](https://github.com/JohnCoates/Aerial/graphs/contributors).

## Installation

**Warning :** Are you using or planning to install 10.15 beta ? If so check [this issue](https://github.com/JohnCoates/Aerial/issues/801) for more information about the current status of Aerial on macOS 10.15 and progress.

Aerial now includes an auto-update mechanism using the [Sparkle open-source project](https://github.com/sparkle-project/Sparkle). You will need to download it manually the first time :

1. Quit **System Preferences**.
2. [Download the latest release of `Aerial.saver.zip`](https://github.com/JohnCoates/Aerial/releases/latest). Alternatively, you can try the latest beta version [following this link](https://github.com/JohnCoates/Aerial/releases). 
3. Unzip the downloaded file (if you use Safari, it should already be done for you).
4. Double-click `Aerial.saver`; it will open in `System Preferences` > `Desktop & Screen Saver` and ask you if you want to install for all users or for your user only. Be aware that installing for all users will require a password at install **and each subsequent update, including auto-updates.** By default, Aerial will still share it's video cache if you install multiple times on the same system for each user.

Need more information on install, setup, or uninstall ? Or want to install via homebrew ? Check our extended [instructions here](Documentation/Installation.md). Curious about auto-updates ? [Have a look here](Documentation/AutoUpdates.md).

## What's new in Aerial 1.5.0 (May 31 2019)?

- Completely rewritten multi monitor support. You can now enable and disable individual displays in the new Display tab. There is also a new "Spanned" viewing mode. Selecting this mode will span an Aerial video on all your (selected) screens. You can even adjust the margins between your screens:

![Capture d’écran 2019-05-29 à 14 43 52](https://user-images.githubusercontent.com/37544189/58558342-d116af80-8220-11e9-8bb0-8d26f1e1b6ed.jpg)

- You can now add your own videos to Aerial using the new [Custom Videos feature](Documentation/CustomVideos.md), and play them alongside Aerial videos:

![Capture d’écran 2019-05-30 à 18 01 36](https://user-images.githubusercontent.com/37544189/58646171-24fac480-8305-11e9-98fd-c9ec7ef3a64c.jpg)

You can find more about [version changes here](Documentation/ChangeLog.md).

## Compatibility

Aerial is written in Swift, which requires OS X Mavericks (10.9) or above.  

## Community

- **Found a bug?** Sorry about that! Make sure you are running the latest version and please check our [troubleshooting page](Documentation/Troubleshooting.md) and [our issues](https://github.com/JohnCoates/Aerial/issues), as someone may already have reported it (a beta may be available with the fix you need). Feel free to [open an issue](https://github.com/JohnCoates/Aerial/issues/new), try to be as specific as possible.
- **Have fixed a bug?** We appreciate all pull requests.
- **Can you translate videos names and their descriptions?**. Awesome! [Read here for details](Resources/Community/Readme.md) on how to help us.
- **Have a feature request?** [Open an issue](https://github.com/JohnCoates/Aerial/issues/new). Tell us why it would be useful, and why you and others would want it.
- **Curious about the videos and on a slow connection?** Check [this guide](https://paper.dropbox.com/doc/Aerial-macOS-screen-saver-list-with-version-1.4.6-HvOeL0gNhLpqpIFgmLHaS) by [Hidehiro Nagaoka](https://github.com/hidehiro98).

## Multilanguage support

Aerial features overlay descriptions of the main geographical features displayed in the videos.

![Community Strings example](https://user-images.githubusercontent.com/4295/52958947-75bd6180-3395-11e9-947f-3c77d9f41928.jpg)

These descriptions are available in many languages (Spanish, French, Polish… [check the complete list here](Resources/Community/Readme.md)) and that is only possible thanks to the collaboration and uninterested work of many. To best serve the international community we've defined a translation workflow that allows any person, even with **no technical background** to help translating these descriptions.

If you want to collaborate, please [read the details here](Resources/Community/Readme.md).

## More documentation

Looking for more information ?

- [Having an issue ? Check our list of common issues right here, including workaround for common macOS bugs (like "You cannot use the Aerial screen saver with this version of macOS.") !](Documentation/Troubleshooting.md)
- [Learn more about configuring and running Aerial in offline mode with no network access.](Documentation/OfflineMode.md)
- [Information about HEVC, HDR and hardware decoding](Documentation/HardwareDecoding.md) 
- [How to add your own videos to Aerial](Documentation/CustomVideos.md)
- [More details than you need on the auto-update mechanisms](Documentation/AutoUpdates.md)

## License

[MIT License](https://raw.githubusercontent.com/JohnCoates/Aerial/master/LICENSE)
