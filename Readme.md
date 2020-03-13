<p align="center">
  <img src="https://cloud.githubusercontent.com/assets/499192/10754100/c0e1cc4c-7c95-11e5-9d3b-842d3acc2fd5.gif">
</p>

# Aerial - Apple TV Aerial Views Screen Saver

Aerial is a Mac screensaver based on the new Apple TV screensaver that displays the Aerial movies Apple shot over New York, San Francisco, Hawaii, China, etc. Starting with version 1.6, this also includes the new undersea videos available in tvOS 13!

Aerial is completely open source, so feel free to contribute to its development.

![Github All Releases](https://img.shields.io/github/downloads/johncoates/aerial/total.svg?maxAge=86400)
![GitHub contributors](https://img.shields.io/github/contributors/johncoates/aerial.svg?maxAge=2592000)
[![Build Status](https://travis-ci.org/JohnCoates/Aerial.svg?branch=master)](https://travis-ci.org/JohnCoates/Aerial)
[![codebeat badge](https://codebeat.co/badges/cefd1672-5501-4b79-8d08-c2121cdbc9ed)](https://codebeat.co/projects/github-com-johncoates-aerial-e1c8873e-7a9f-4c74-9e50-0380add2478a)
[![Code Climate](https://codeclimate.com/github/JohnCoates/Aerial/badges/gpa.svg)](https://codeclimate.com/github/JohnCoates/Aerial)
[![codecov](https://codecov.io/gh/JohnCoates/Aerial/branch/master/graph/badge.svg)](https://codecov.io/gh/JohnCoates/Aerial)

###### Windows user? Try [cDima/Aerial](https://github.com/cDima/Aerial/) Linux user? Try [graysky2/xscreensaver-aerial](https://github.com/graysky2/xscreensaver-aerial/)

Aerial was started in 2015 by John Coates ([Twitter](https://twitter.com/JohnCoatesDev), [Email](mailto:john@johncoates.me))

Starting with version 1.4, Aerial is maintained by [Guillaume Louel](https://github.com/glouel) ([Twitter](https://twitter.com/C_Wiz), [![Support via PayPal][paypal-button]][paypal-glouel]).

[paypal-button]: https://img.shields.io/badge/Donate-PayPal-green.svg
[paypal-glouel]: https://www.paypal.me/glouel/

You can see a list of contributors [here](https://github.com/JohnCoates/Aerial/graphs/contributors).

## Installation

**Please note :** Starting with Catalina, Aerial will only notify you of new versions, but won't be able to automatically update itself. This is a limitation of macOS Catalina.

Installation instructions (latest versions require macOS 10.12 or above) :

1. Quit **System Preferences**.
2. [Download the latest release of `Aerial.saver.zip`](https://github.com/JohnCoates/Aerial/releases/latest). Alternatively, you can find the [latest beta here](https://github.com/JohnCoates/Aerial/releases). 
3. Unzip the downloaded file (if you use Safari, it should already be done for you).
4. Double-click `Aerial.saver`; it will open in `System Preferences` > `Desktop & Screen Saver` and ask you if you want to install for all users or for your user only. Be aware that installing for all users will require a password at install **and each subsequent update, including auto-updates.** By default, Aerial will still share its video cache if you install multiple times on the same system for each user.

Need more information on install, setup, or uninstall ? Or want to install via homebrew ? Check our extended [instructions here](Documentation/Installation.md). Curious about auto-updates ? [Have a look here](Documentation/AutoUpdates.md).

## What's new in Aerial 1.8.0 (February 18, 2020)?

- New update system for macOS Catalina. Starting with version 1.8.0, Aerial will now by default notify you with a message while the screen saver runs, when a new version of Aerial is available :

![Capture d’écran 2020-02-18 à 17 57 39](https://user-images.githubusercontent.com/37544189/74758954-5858f700-5278-11ea-8e17-d034fdf57f33.jpg)

You will also be notified when a new version is available in Aerial's settings, with that new mechanism that will redirect you to the new release page where you can download the new version :
![Capture d’écran 2020-02-18 à 17 59 28](https://user-images.githubusercontent.com/37544189/74759068-7f172d80-5278-11ea-99bf-08621550087b.jpg)

The update check process still uses Sparkle, but Aerial is not able to auto update in macOS Catalina due to the new sandboxing restrictions. I apologize for the inconvenience.

- Add new shadow controls :

![Capture d’écran 2020-02-18 à 18 06 26](https://user-images.githubusercontent.com/37544189/74759836-b3d7b480-5279-11ea-84cf-3ddbc810cbce.jpg)

- Add a new Countdown information option, to either countdown to a given date, or a given time of day :

![Capture d’écran 2020-02-18 à 18 07 49](https://user-images.githubusercontent.com/37544189/74759838-b4704b00-5279-11ea-8446-9cad67da60ea.jpg)

This version also fixes many issues with macOS Catalina, namely localization that always defaulted to English, due to the restrictions applied by `legacyScreenSaver.appex`'s sandboxing. Starting with 1.8.0, Aerial requires at least macOS 10.12.

You can find more about [version changes here](Documentation/ChangeLog.md).

## Compatibility

Aerial is written in Swift, which requires OS X Sierra (10.12) or above. Aerial 1.7.1 is the last version that supports macOS 10.9. 

## Community

- **Found a bug?** Sorry about that! Make sure you are running the latest version and please check our [troubleshooting page](Documentation/Troubleshooting.md) and [our issues](https://github.com/JohnCoates/Aerial/issues), as someone may already have reported it (a beta may be available with the fix you need). Feel free to [open an issue](https://github.com/JohnCoates/Aerial/issues/new), try to be as specific as possible.
- **Have fixed a bug?** Or want to implement a feature ? Check instructions on how to compile Aerial and more on [contributing here](Documentation/Contribute.md).
- **Can you translate videos names and their descriptions?**. Awesome! [Read here for details](Resources/Community/Readme.md) on how to help us.
- **Have a feature request?** [Open an issue](https://github.com/JohnCoates/Aerial/issues/new). Tell us why it would be useful, and why you and others would want it.
- **Curious about the videos and on a slow connection?** Check [this guide](https://paper.dropbox.com/doc/Aerial-macOS-screen-saver-list-with-version-1.4.6-HvOeL0gNhLpqpIFgmLHaS) by [Hidehiro Nagaoka](https://github.com/hidehiro98).
- **Just want to see the videos?** [A complete list of available wallpapers  is available online](https://aerial-screensavers.netlify.com). From [TawfiqH](https://github.com/Tawfiqh/aerialWallpapers).


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
