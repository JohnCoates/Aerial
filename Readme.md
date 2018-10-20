![screencast](https://cloud.githubusercontent.com/assets/499192/10754100/c0e1cc4c-7c95-11e5-9d3b-842d3acc2fd5.gif)

## Aerial - Apple TV Aerial Views Screen Saver
Aerial is a Mac screen saver based on the new Apple TV screen saver that displays the aerial movies Apple shot over New York, San Francisco, Hawaii, China, etc. Starting with version 1.4, this also includes the new ISS videos available in tvOS 12! 

Aerial is completely open source, so feel free to contribute to its development.

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

Version 1.4 is also maintained by :
- [Guillaume Louel](https://github.com/glouel) ([Twitter](https://twitter.com/C_Wiz))
- [Ethan Setnik](https://github.com/esetnik)

You can see a list of contributors [here](https://github.com/JohnCoates/Aerial/graphs/contributors). 

## Installation

### Manual Installation
*Rather install from Terminal or have auto-updates? Look at the Brew Cask section below!*

1. [Click here to Download](https://github.com/JohnCoates/Aerial/releases/download/v1.4.1/Aerial.saver.zip) (Version 1.4.1, October 16, 2018, see [changes here](https://github.com/JohnCoates/Aerial/releases/tag/v1.4.1)) (1.4.2 beta 1, October 20, 2018, is also available [here](https://github.com/JohnCoates/Aerial/releases/download/v1.4.2beta1/Aerial.saver.zip), [click here](https://github.com/JohnCoates/Aerial/releases/tag/v1.4.2beta1) for more information on what's changed)
2. Unzip the downloaded file.
3. Open **Aerial.saver** and confirm installation.

If Aerial.saver could not be opened, place Aerial.saver in `~/Library/Screen Savers`

**Important**: Please note that if you are upgrading from a previous version, we strongly recommend you close System Preferences after the installation and reopen it, as Swift screensavers aren't loaded correctly otherwise when updated. Also please note that clicking on the Preview button with 1.4.1 in System Preferences will show you a black screen. The screensaver will still work correctly. This bug is fixed in 1.4.2 beta (See above).

### Brew Cask Support - (Updated for Version 1.4.1)

If you're looking to install Aerial across many systems, remotely, or simply from Terminal we recommend [Brew Cask](https://caskroom.github.io). Prefer this method if you're looking for auto-updates.

Simply issue the following Terminal command: `brew cask install aerial`

To upgrade Aerial, run `brew cask upgrade` in Terminal.

## Setting Aerial as Your Screen Saver

1. Open `System Preferences` -> `Desktop & Screen Saver` -> `Screen Saver`
2. Choose Aerial and click on Screen Saver Options to select your settings.

![screen shot 2018-10-11 at 14 47 09](https://user-images.githubusercontent.com/37544189/46805565-ad702900-cd65-11e8-9779-91243ee9e634.png)

## Uninstallation

There are three options to uninstall Aerial from your Mac.

* Right-click on the Aerial screensaver in System Preferences and select `Delete "Aerial"`.
* Or delete the file(s) directly. macOS can store screen savers in two locations. `/Library/Screen Savers` and `/Users/YOURUSERNAME/Library/Screen Savers`. Check both locations for a file called "Aerial.saver" and delete any copies you find.
* If you installed Aerial using Brew Cask, then the following command in a Terminal window should remove the Brew Cask installed version. `brew cask uninstall aerial`

You may also want to delete the folder `/Users/YOURUSERNAME/Library/Caches/Aerial`. This is where Aerial stores the cached copies of the Aerial videos. The last thing, you may want to delete the preferences `plist`. The file is `/Users/YOURUSERNAME/Library/Preferences/ByHost/com.JohnCoates.Aerial.{UUID}.plist`. It's highly recommended to remove that file if you purge the Cache folder.

## New features in version 1.4+

![screen shot 2018-10-11 at 14 49 52](https://user-images.githubusercontent.com/37544189/46805573-b3660a00-cd65-11e8-9e40-152d170ffd8e.png)

* **Every Aerial video:** From the very first Aerials in San Francisco to the new space videos shot from the ISS! Now with better titles too so you can find your favorite videos faster.
* **4K HEVC:** With the launch of Apple TV 4K, many videos are now available in this format. Aerial will show you the best format available based on your preferences.
* **Different videos based on time:** Want to see night videos at night? You can either specify your sunset or sunrise time manually or, if your Mac is compatible with Night Shift (See [here for a list of compatible Macs](https://support.apple.com/en-us/HT207513)), get those automatically (You do not need to enable Night Shift).
* **Feeling Dark?:** Aerial is now compatible with Dark Mode in macOS 10.14 Mojave and can play night videos when Dark Mode is enabled.

![screen shot 2018-10-11 at 14 50 18](https://user-images.githubusercontent.com/37544189/46805577-b5c86400-cd65-11e8-8c04-252c5fa6c1eb.png)

* **Descriptions:** Wondering where an Aerial view was shot? Aerial can now tell you as they play. New in 1.4.1, we even have extra descriptions on the "original" videos (London, New York, San Francisco...)
* **Full offline mode::** Behind a firewall? Just copy the cache folder from another Mac and you are all set. You can also disable all streaming. 
* **Better cache management:** You can now cache your favorite videos individually, no need to grab them all. Or just stream them as you go, they'll get cached automatically too.
* **Clock:** We even have a properly styled clock if that's your thing! 
* **And many bug fixes!**


## Compatibility
Aerial is written in Swift, which requires OS X Mavericks (10.9) or above.

## Community
- **Found a bug?** [Open an issue](https://github.com/JohnCoates/Aerial/issues/new). Try to be as specific as possible.
- **Have a feature request?** [Open an issue](https://github.com/JohnCoates/Aerial/issues/new). Tell us why this feature would be useful, and why you and others would want it.

## Contribute
We appreciate all pull requests.

## Offline Mode
If you want to use Aerial on a Mac behind a firewall or with no network access, the easiest way starting with version 1.4 is to copy the content of the cache folder from another Mac where Aerial is already installed. 

If that's not an option, you can manually recreate a cache folder by downloading files manually. 
- Download and untar `https://sylvan.apple.com/Aerials/resources.tar` (tvOS12 resources, keep the tar *and* extracted files)
- Download and rename `https://sylvan.apple.com/Aerials/2x/entries.json` to `tvos11.json` (tvOS11 resources, also in 4K)
- Download and rename `http://a1.phobos.apple.com/us/r1000/000/Features/atv/AutumnResources/videos/entries.json` to `tvos10.json` (the original Aerials, in 1080p H.264 only)

You can then download the videos you want from the JSON files. In the 4K JSONs, you are looking for the `url-1080-H264` (1080p H.264, most compatible format), `url-1080-SDR` (1080p HEVC, better quality, requires a recent Mac for hardware decoding) or `url-4K-SDR` (4K HEVC).

## About HEVC and hardware decoding

Aerial uses Apple's AV Framework to play the videos as your screensaver. When available, AV Framework will use hardware decoding (from your CPU or your graphics card) to minimize the resources needed for video playback. You can find guidelines in the help button next to the `Preferred video format` setting. By default, Aerial uses 1080p H.264 videos which is the most compatible format. Please note that all HEVC videos are encoded with the `Main10` profile, which may not be hardware accelerated by your machine, while some other HEVC videos (encoded in `Main` profile) will be.

While we wish to provide everyone with the best setting for their machine, the GVA framework from Apple doesn't let us distinguish HEVC `Main10` profile acceleration from general HEVC acceleration. Early feedback we gathered also seems to point that on machines with multiple decoding options (Intel QuickSync and AMD UVD), QuickSync will always be preferred (even if you "force" the discrete GPU use with an external monitor).

These are our recommendations so far:
- Macs older than 2011 may lack H.264 acceleration. 
- Macs with an Intel CPU (with iGPU) from the Sandy Bridge (2011) generation to Broadwell (early 2015) should have H.264 hardware acceleration available.
- Late 2015 and 2016 Macs (Skylake and Kaby Lake) may only have partially accelerated HEVC decoding. We recommended you stick to 1080p H.264 on laptops. You may consider the HEVC format on desktops but understand that decoding may be CPU intensive and spin up your fans.
- Macs 2017 and up should have full HEVC acceleration. 

You can easily check for yourself what to expect by opening a video in Quicktime (use the `Show in Finder` option in the `Cache` tab to find the cached videos). In activity monitor, the AV Framework GVA process is called `VTDecoderXPCService`.

## Troubleshooting

- Not seeing extended descriptions: If you manually removed your cache folder, you may no longer see the extra descriptions on video (eg, you only see "Space" on Space videos and City names for every single video). If that's the case, it's likely you have deleted the `TVIdleScreenStrings.bundle` from your cache directory. To restore it, two solutions :
1) Close System Preferences, delete `/Users/YOURUSERNAME/Library/Preferences/ByHost/com.JohnCoates.Aerial.{UUID}.plist`, and go back to System Preferences and open Aerial again. It should redownload the missing file. 
2) Download manually `https://sylvan.apple.com/Aerials/resources.tar` and put that file in the Aerial cache folder (you can open that folder from the Cache panel, by clicking the `Show in Finder` button. You will need to extract the tar. Make sure that the extracted files are at the root of the cache folder, and not in a resources subfolder (some unarchiving tools will do that by default). If so, just move the content of the resources folder to the parent directory.
- Black screen: If you are behind a firewall (like Little Snitch or Hands Off!) try creating exceptions for Aerial to allow it access to Apple's servers. Be sure the applications `ScreenSaverEngine.app` and `System Preferences.app` are not being blocked access to *.phobos.apple.com, *.phobos.apple.com.edgesuite.net and sylvan.apple.com. If that isn't an option, please look at the Offline mode section. 
- "You cannot use the Aerial screen saver with this version of macOS." error: Select Aerial, close System Preferences with Aerial still selected, re-open System Preferences and Aerial should now work. This is a known bug with Swift screensavers in macOS/OS X reported to Apple as [rdar://25569037](http://www.openradar.me/25569037).
- High CPU usage/fan spinning all of a sudden: If you correctly configured the preferred video format according to your Mac and still experience high CPU usage/fan spinning all of a sudden, please look for the cause with `Activity Monitor`, you may see   a `com.apple.photos.ImageConversionService` responsible for this CPU load. This is the iCloud Photos process, you can find more about [what it does here](https://support.apple.com/en-gu/HT204264) and how to pause it.


## License
[MIT License](https://raw.githubusercontent.com/JohnCoates/Aerial/master/LICENSE)
