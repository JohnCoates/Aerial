![screencast](https://cloud.githubusercontent.com/assets/499192/10754100/c0e1cc4c-7c95-11e5-9d3b-842d3acc2fd5.gif)

# Aerial - Apple TV Aerial Views Screen Saver

Aerial is a Mac screensaver based on the new Apple TV screensaver that displays the Aerial movies Apple shot over New York, San Francisco, Hawaii, China, etc. Starting with version 1.4, this also includes the new ISS videos available in tvOS 12!

Aerial is completely open source, so feel free to contribute to its development.

![Github All Releases](https://img.shields.io/github/downloads/johncoates/aerial/total.svg?maxAge=86400)
![GitHub contributors](https://img.shields.io/github/contributors/johncoates/aerial.svg?maxAge=2592000)
[![Build Status](https://travis-ci.org/JohnCoates/Aerial.svg?branch=master)](https://travis-ci.org/JohnCoates/Aerial)
[![codebeat badge](https://codebeat.co/badges/cefd1672-5501-4b79-8d08-c2121cdbc9ed)](https://codebeat.co/projects/github-com-johncoates-aerial-e1c8873e-7a9f-4c74-9e50-0380add2478a)
[![Code Climate](https://codeclimate.com/github/JohnCoates/Aerial/badges/gpa.svg)](https://codeclimate.com/github/JohnCoates/Aerial)
[![codecov](https://codecov.io/gh/JohnCoates/Aerial/branch/master/graph/badge.svg)](https://codecov.io/gh/JohnCoates/Aerial)

###### Windows user? Try [cDima/Aerial](https://github.com/cDima/Aerial/)

###### Linux user? Try [graysky2/xscreensaver-aerial](https://github.com/graysky2/xscreensaver-aerial/)

#### Coded with Love by John Coates ([Twitter](https://twitter.com/JohnCoatesDev), [Email](mailto:john@johncoates.me))

Starting with version 1.4, Aerial is also maintained by:

- [Guillaume Louel](https://github.com/glouel) ([Twitter](https://twitter.com/C_Wiz))

You can see a list of contributors [here](https://github.com/JohnCoates/Aerial/graphs/contributors).

## Installation

### Manual Installation

_Rather install from Terminal or have auto-updates? Look at the Brew Cask section below!_

1. Quit **System Preferences**.
2. [Download the latest release of Aerial.saver.zip](https://github.com/JohnCoates/Aerial/releases/latest). (Version 1.4.9, May 1st 2019). Alternatively, you can try the latest beta version [following this link](https://github.com/JohnCoates/Aerial/releases). 
3. Unzip the downloaded file (if you use Safari, it should already be done for you).
4. Double-click `Aerial.saver`; it will open in `System Preferences` > `Desktop & Screen Saver` and ask you if you want to install for all users or for your user only.

   If you see an error message saying "This app is damaged and can't be opened, you should move it to the trash", we suggest that **you download the file with Safari**, to prevent macOS Gatekeeper from throwing that error. Note that some outdated unzip software may cause that issue too.

   **Important**: If you haven't quit System Preferences before installation and were upgrading from a previous version, we strongly recommend you quit the application after installation, then reopen it, as updated Swift screensavers aren't loaded correctly in an active System Preferences session.

### Brew Cask Support - (Updated to 1.4.9)

If you're looking to install Aerial across many systems, remotely, or simply from Terminal we recommend [Brew Cask](https://caskroom.github.io). Prefer this method if you're looking for auto-updates.

Simply issue the following Terminal command:

```sh
brew cask install aerial
```

To upgrade Aerial, run the following Terminal command:

```sh
brew cask upgrade aerial
```

Please note that if you prefer using homebrew to update Aerial, we recommend you disable Sparkle auto updates in the `Updates`tab. 

## Setting Aerial as Your Screen Saver

1. Open `System Preferences` -> `Desktop & Screen Saver` -> `Screen Saver`
2. Choose Aerial and click on `Screen Saver` Options to select your settings.

![screen shot 2018-10-29 at 13 17 23](https://user-images.githubusercontent.com/37544189/47649971-1f76a980-db7f-11e8-97be-d1f90b943c9d.png)

## Uninstallation

There are three options to uninstall Aerial from your Mac.

- Right-click on the Aerial screensaver in `System Preferences` and select `Delete "Aerial"`.
- Or delete the file(s) directly. macOS can store screen savers in two locations. `/Library/Screen Savers` and `/Users/YOURUSERNAME/Library/Screen Savers`. Check both locations for a file called `Aerial.saver` and delete any copies you find.
- If you installed Aerial using Brew Cask, then enter the following command in a Terminal window to uninstall:

```sh
brew cask uninstall aerial.
```

You may also want to delete the folder `/Users/YOURUSERNAME/Library/Caches/Aerial` (or `/Library/Caches/Aerial`). This is where Aerial stores the cached copies of the Aerial videos. The last thing, you may want to delete the preferences `plist`. The file is `/Users/YOURUSERNAME/Library/Preferences/ByHost/com.JohnCoates.Aerial.{UUID}.plist`.

## New features in 1.4.8

This latest version includes many new features and enhancements:

- **5 new videos available in 4K:** Following the content update from January 25th, Aerial now includes 73 videos, 65 of which are also available in 4K. Aerial will periodically check for new videos, you can manage this in the `Updates` tab. 
- **Automatic updates support through Sparkle:** Aerial now uses Sparkle to automatically updates itself, including when your screensaver runs. All of this can be managed in the `Updates` tab. 

![Capture d’écran 2019-04-30 à 18 31 20](https://user-images.githubusercontent.com/37544189/56977789-4afe3f00-6b76-11e9-9985-1ca1a1866d6b.jpg)

- **Localization for community support** in Arabic, Chinese Simplified, English, French, German, Hebrew, Polish and Spanish! Thanks to all the contributors. If you want to help,  please [read the details here](Resources/Community/Readme.md).
- **You can now skip an Aerial with the right arrow key**
- **You can now save your favorite videos sets to enable them quickly**

<img width="377" alt="Capture d’écran 2019-04-19 à 14 28 55" src="https://user-images.githubusercontent.com/37544189/56425106-35099800-62b3-11e9-9689-315a34132e21.png">

## Multilanguage support

Aerial features overlay descriptions of the main geographical features displayed in the videos.

![Community Strings example](https://user-images.githubusercontent.com/4295/52958947-75bd6180-3395-11e9-947f-3c77d9f41928.jpg)

These descriptions are available in many languages (Spanish, French, Polish… [check the complete list here](Resources/Community/Readme.md)) and that is only possible thanks to the collaboration and uninterested work of many. To best serve the international community we've defined a translation workflow that allows any person, even with **no technical background** to help translating these descriptions.

If you want to collaborate, please [read the details here](Resources/Community/Readme.md).

## Features

![screen shot 2018-10-29 at 13 21 05](https://user-images.githubusercontent.com/37544189/47649972-1f76a980-db7f-11e8-910b-1d5d50931ae2.png)

- **Every Aerial video:** From the very first Aerials in San Francisco to the new space videos shot from the ISS! Now with better titles too so you can find your favorite videos faster.
- **4K HEVC:** With the launch of Apple TV 4K, many videos are now available in this format (With version 1.4.6, 60 of the 70 videos are available in 4K!). Aerial will show you the best format available, based on your preferences.

![screen shot 2018-10-29 at 13 24 36](https://user-images.githubusercontent.com/37544189/47649973-1f76a980-db7f-11e8-8aef-301307d48fa2.png)

- **Different videos based on time:** Want to see night videos at night? Aerial can calculate for you the dusk/dawn times. You can also use Night Shift sunset and sunrise detection (See [here for a list of compatible Macs](https://support.apple.com/en-us/HT207513), you do not need to enable Night Shift).
- **Feeling Dark?:** Aerial is now compatible with Dark Mode in macOS 10.14 Mojave and can play night videos when Dark Mode is enabled.

![screen shot 2018-10-29 at 13 24 46](https://user-images.githubusercontent.com/37544189/47649974-1f76a980-db7f-11e8-8339-3f0424652b8c.png)

- **Descriptions:** Wondering where an Aerial view was shot? Aerial can now tell you as they play. We even have extended descriptions written by our community of users. Help us to improve these descriptions by [translating them to your language](Resources/Community/Readme.md).

![screen shot 2018-10-29 at 13 25 10](https://user-images.githubusercontent.com/37544189/47649975-200f4000-db7f-11e8-9e8b-f75c4a5ebde4.png)

- **Remove video duplicates:** Aerial can now cleanup your old videos (They are periodically updated to fix colors, provide longer versions of previously existing videos, or upgraded to 4K). Go to the `Advanced` Tab and either move the files away or send them to the trash to reclaim free space. The `Move old videos` button will move the video files to a directory created within the Aerial cache called `oldvideos`, which will contain a dated directory within it. You can find them at `/Users/YOURUSERNAME/Library/Caches/Aerial/oldvideos/YYYY-MM-DD`

![capture d ecran 2018-12-13 a 15 06 49](https://user-images.githubusercontent.com/37544189/49943901-60394080-fee9-11e8-93b0-3cc68087b70e.png)

- **Brightness control:** Aerial can progressively dim the brightness of your screens before your Mac goes to sleep. You can even enable this feature only at night, or only on battery if you prefer.
- **Full offline mode:** Behind a firewall? Just copy the cache folder from another Mac and you are all set. You can also disable all streaming.
- **Better cache management:** You can now cache your favorite videos individually, no need to grab them all. Or just stream them as you go, they'll get cached automatically too.
- **Show videos in Quicktime:** You can now right click a video to open it in Quicktime.
- **More battery controls:** Using Aerial on a Macbook? You can now specify a different video format on battery mode if you wish, or simply video playback using the Power Saving mode (Aerial will show a blank screen and reduce screen brightness instead of showing videos).
- **Clock:** We even have a properly styled clock if that's your thing!
- **And many bug fixes!**

## Compatibility

Aerial is written in Swift, which requires OS X Mavericks (10.9) or above.

## Community

- **Found a bug?** [Open an issue](https://github.com/JohnCoates/Aerial/issues/new). Try to be as specific as possible.
- **Have fixed a bug?** We appreciate all pull requests.
- **Can you translate the video descriptions?**. Awesome! [Read here for details](Resources/Community/Readme.md) on how to help us.
- **Have a feature request?** [Open an issue](https://github.com/JohnCoates/Aerial/issues/new). Tell us why it be useful, and why you and others would want it.
- **Curious about the videos and on a slow connection?** Check [this guide](https://paper.dropbox.com/doc/Aerial-macOS-screen-saver-list-with-version-1.4.6-HvOeL0gNhLpqpIFgmLHaS) by [Hidehiro Nagaoka](https://github.com/hidehiro98).

## Offline Mode

If you want to use Aerial on a Mac behind a firewall or with no network access, the easiest way starting with version 1.4 is to copy the content of the cache folder from another Mac where Aerial is already installed.

If that's not an option, you can manually recreate a cache folder by downloading files manually.

- Download and untar `https://sylvan.apple.com/Aerials/resources.tar` (tvOS12 resources, keep the tar _and_ extracted files)
- Download and rename `https://sylvan.apple.com/Aerials/2x/entries.json` to `tvos11.json` (tvOS11 resources, also in 4K)
- Download and rename `http://a1.phobos.apple.com/us/r1000/000/Features/atv/AutumnResources/videos/entries.json` to `tvos10.json` (The original Aerials, in 1080p H.264 only)

You can then download the videos you want from the JSON files. In the 4K JSONs, you are looking for the `url-1080-H264` (1080p H.264, most compatible format), `url-1080-SDR` (1080p HEVC, better quality, requires a recent Mac for hardware decoding) or `url-4K-SDR` (4K HEVC). As of macOS Mojave, the HDR versions of these videos won't play on Quicktime or AVFoundation, so avoid them.

## About HEVC and hardware decoding

Aerial uses Apple's [AVFoundation framework](https://developer.apple.com/documentation/avfoundation) to play the videos as your screensaver. When available, AVFoundation will use hardware decoding (From your CPU or your graphics card) to minimize the resources needed for video playback. You can find guidelines in the help button next to the `Preferred video format` setting. By default, Aerial uses 1080p H.264 videos which is the most compatible format. Please note that all HEVC videos are encoded with the `Main10` profile, which may not be hardware accelerated by your machine, while some other HEVC videos (Encoded in `Main` profile) will be.

While we wish to provide everyone with the best setting for their machine, the GVA framework from Apple doesn't let us distinguish HEVC `Main10` profile acceleration from general HEVC acceleration. Early feedback we gathered also seems to point that on machines with multiple decoding options (Intel QuickSync and AMD UVD), QuickSync will always be preferred (Even if you "force" the discrete GPU use with an external monitor).

These are our recommendations so far:

- Macs older than 2011 may lack H.264 acceleration.
- Macs with an Intel CPU (With iGPU) from the Sandy Bridge (2011) generation to Broadwell (Early 2015) should have H.264 hardware acceleration available.
- Late 2015 and 2016 Macs (Skylake and Kaby Lake) may only have partially accelerated HEVC decoding. We recommended you stick to 1080p H.264 on laptops. You may consider the HEVC format on desktops but understand that decoding may be CPU intensive and spin up your fans.
- Macs 2017 and up should have full HEVC acceleration.

You can easily check for yourself what to expect by opening a video in Quicktime (Use the `Show in Finder` option in the `Cache` tab to find the cached videos). In Activity Monitor, the AV Framework GVA process is called `VTDecoderXPCService`.

## Troubleshooting

- Aerial logs you out of your user account everytime it starts: This looks like a new bug with macOS 10.14.5 beta 18F108f, possibly only for Macs with Intel graphics. As a workaround, please tick the Show Clock option in the main screensaver settings (not on Aerial settings). More information here : https://github.com/JohnCoates/Aerial/issues/738
- Videos keeps disappearing, Aerial may not restart once in a while: Aerial stores all it's data in a Cache folder. This cache may get deleted by some third party software trying to free disk space. If you use such a "Cleaning" tool, we recommend you set a manual folder location in the Cache tab of Aerial. For example, you can create an Aerial folder in your User folder, and point to it. This will ensure Aerial files don't get deleted.
- "Done" button doesn't close Aerial: Please update to latest available version, this is a bug on Mojave with very old versions of Aerial (1.2 and below).
- Can't type into text fields with macOS High Sierra/Video corruption issue on High Sierra: Please make sure you have at least version 1.4.5.
- "This app is damaged and can't be opened, you should move it to the trash" when double-clicking the `Aerial.saver` file: Please see the installation notes above, this is a GateKeeper issue.
- Brightness control does not control external displays: Aerial uses the brightness API from macOS to change the brightness of your screens. Depending on your external screens (brand, the way they are connected, etc), macOS may not be able to control their brightness. Please check first if you can control the brightness of your external screen(s) using the brightness keys from your keyboard. If you can't, Aerial won't be able to control their brightness either. If you can control their brightness through those keyboard keys but see an issue with Aerial, please open an issue.
- Not seeing extended descriptions: Make sure you have version 1.4.2 or above.
- Black screen: If you are behind a firewall (Like Little Snitch or Hands Off!) try creating exceptions for Aerial to allow it access to Apple's servers. Be sure the applications `ScreenSaverEngine.app` and `System Preferences.app` are not being blocked access to `*.phobos.apple.com`, `*.phobos.apple.com.edgesuite.net` and `sylvan.apple.com`. If that isn't an option, please look at the Offline mode section.
- "You cannot use the Aerial screen saver with this version of macOS." error: Select Aerial, close `System Preferences` with Aerial still selected, re-open System Preferences and Aerial should now work. This is a known bug with Swift screensavers in macOS/OS X reported to Apple as [rdar://25569037](http://www.openradar.me/25569037).
- High CPU usage/fan spinning all of a sudden: If you correctly configured the preferred video format according to your Mac and still experience high CPU usage/fan spinning all of a sudden, please look for the cause with `Activity Monitor`, you may see a `com.apple.photos.ImageConversionService` responsible for this CPU load. This is the iCloud Photos process, you can find more about [what it does here](https://support.apple.com/en-gu/HT204264) and how to pause it.
- Can't use Aerial as a login screensaver: As far as we know, using 3rd party screensavers before login is no longer possible on modern versions of macOS. More about this [here](https://github.com/JohnCoates/Aerial/issues/571).
- Change cache location : This option simply changes _the location_ of the Cache folder that Aerial uses. It does _not_ move your files for you. Please note that this change will only be taken into account the next time Aerial starts (you may need to fully close System Preferences). We strongly recommend you use a path that's always accessible, as Aerial can't work without a Cache directory. In case the path is no longer available (missing USB key, etc), starting with Aerial 1.4.7, it will reset the Cache location to it's default location.

## License

[MIT License](https://raw.githubusercontent.com/JohnCoates/Aerial/master/LICENSE)
