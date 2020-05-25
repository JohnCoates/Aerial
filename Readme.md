<p align="center">
  <img src="https://cloud.githubusercontent.com/assets/499192/10754100/c0e1cc4c-7c95-11e5-9d3b-842d3acc2fd5.gif">
</p>

# Aerial - Apple TV Aerial Views Screen Saver

Aerial is a Mac screensaver based on the new Apple TV screensaver that displays the Aerial movies Apple shot over New York, San Francisco, Hawaii, China, etc. Starting with version 1.6, this also includes the new undersea videos available in tvOS 13 ! See here for a [complete list of available videos.](https://aerial-screensavers.netlify.com)

Aerial is completely open source, so feel free to contribute to its development.

![Github All Releases](https://img.shields.io/github/downloads/johncoates/aerial/total.svg?maxAge=86400)
![GitHub contributors](https://img.shields.io/github/contributors/johncoates/aerial.svg?maxAge=2592000)
[![Build Status](https://travis-ci.org/JohnCoates/Aerial.svg?branch=master)](https://travis-ci.org/JohnCoates/Aerial)
[![codebeat badge](https://codebeat.co/badges/cefd1672-5501-4b79-8d08-c2121cdbc9ed)](https://codebeat.co/projects/github-com-johncoates-aerial-e1c8873e-7a9f-4c74-9e50-0380add2478a)
[![Code Climate](https://codeclimate.com/github/JohnCoates/Aerial/badges/gpa.svg)](https://codeclimate.com/github/JohnCoates/Aerial)
[![codecov](https://codecov.io/gh/JohnCoates/Aerial/branch/master/graph/badge.svg)](https://codecov.io/gh/JohnCoates/Aerial)

###### Windows user? Try [OrangeJedi/Aerial](https://github.com/OrangeJedi/Aerial) Linux user? Try [graysky2/xscreensaver-aerial](https://github.com/graysky2/xscreensaver-aerial/)

Aerial was started in 2015 by John Coates ([Twitter](https://twitter.com/JohnCoatesDev), [Email](mailto:john@johncoates.me))

Starting with version 1.4, Aerial is maintained by [Guillaume Louel](https://github.com/glouel) ([Twitter](https://twitter.com/C_Wiz)). If you are looking to support the development of Aerial, feel free to donate using the following button [![Support via PayPal][paypal-button]][paypal-glouel].

[paypal-button]: https://img.shields.io/badge/Donate-PayPal-green.svg
[paypal-glouel]: https://www.paypal.me/glouel/

You can see a list of contributors [here](https://github.com/JohnCoates/Aerial/graphs/contributors).

## Installation

**Please note :** Starting with Catalina, Aerial will only notify you of new versions, but won't be able to automatically update itself. This is a limitation of macOS Catalina.

Installation instructions (latest versions require macOS 10.12 or above) :

1. Quit **System Preferences**.
2. [Download the latest release of `Aerial.saver.zip`](https://github.com/JohnCoates/Aerial/releases/latest). Alternatively, you can find the [latest beta here](https://github.com/JohnCoates/Aerial/releases). 
3. Unzip the downloaded file (if you use Safari, it should already be done for you).
4. Double-click `Aerial.saver`; it will open in `System Preferences` > `Desktop & Screen Saver` and ask you if you want to install for all users or for your user only. Be aware that installing for all users will require a password at install **and each subsequent update, including auto-updates.** 

Need more information on install, setup, or uninstall ? Or want to install via homebrew ? Check our extended [instructions here](Documentation/Installation.md). Curious about auto-updates ? [Have a look here](Documentation/AutoUpdates.md).

## What's new in Aerial 1.9.0 (May 25, 2020)?

![Capture d’écran 2020-05-25 à 15 46 42](https://user-images.githubusercontent.com/37544189/82818568-338ba580-9e9f-11ea-8f26-90b23958f587.jpg)

- Weather ! Aerial can now display current conditions for a location of your choice using Yahoo! Weather's API. 

This feature can be enabled and configured inside the Info tab. 

![Capture d’écran 2020-05-25 à 15 44 37](https://user-images.githubusercontent.com/37544189/82818567-32f30f00-9e9f-11ea-81d1-cce630b224eb.jpg)

You can either manually specify a location, or use your mac's location services to provide Aerial with your most recent location when it starts. To preserve your privacy, should you wish to use location services, Aerial will only provide your location with an approximate 1km margin of error. 

- Graphical battery indicator. The old text battery indicator was replaced with a nicer graphical one :

<center><img width="240" alt="Capture d’écran 2020-05-25 à 15 58 33" src="https://user-images.githubusercontent.com/37544189/82819429-a6e1e700-9ea0-11ea-9c1f-0a371413174b.png"></center>

This [version](https://github.com/JohnCoates/Aerial/releases/tag/v1.9.0) also includes several extra refinements such as adding the ability to override the 12/24 hour format for the clock, and also includes Italian translation thanks to @marguglio. 

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
