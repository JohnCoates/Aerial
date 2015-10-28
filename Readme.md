![screencast](https://cloud.githubusercontent.com/assets/499192/10754100/c0e1cc4c-7c95-11e5-9d3b-842d3acc2fd5.gif)

## Aerial - Apple TV Aerial Views Screen Saver
Aerial is a Mac screen saver based on the new Apple TV screen saver that displays the aerial movies Apple shot over New York, San Francisco, Hawaii, China, etc.

Aerial is completely open source, so feel free to contribute to its development!

#### Coded with Love by John Coates

[![Twitter](http://i.imgur.com/KzOiue1.png)](http://twitter.com/punksomething)
[![Email](http://i.imgur.com/FvDZudR.png)](mailto:john@johncoates.me)

## Download
Download from [Github](https://github.com/JohnCoates/Aerial/releases/download/v1.1/Aerial.zip)

Two ways to install:

**Option A:** Open Aerial.saver and OS X will ask if you'd like it installed.

**Option B:** Place Aerial.saver in ~/Library/Screen Savers

## Using Aerial

To enable Aerial open System Preferences -> Desktop & Screen Saver -> Screen Saver

Choose Aerial and click on Screen Saver Options to select your settings.

![screenshot](https://cloud.githubusercontent.com/assets/499192/10754102/c58cc076-7c95-11e5-9579-4275740ba339.png)

## Add Local Cahce

You can add the mov file cache to Aerial.

1. Download the `mov` files form [http://a1.phobos.apple.com/us/r1000/000/Features/atv/AutumnResources/videos/entries.json](http://a1.phobos.apple.com/us/r1000/000/Features/atv/AutumnResources/videos/entries.json) 

2. Put them into `~/Downloads/AerialMovCache/` ( Just add a new folder `AerialMovCache` in your `Downloads` and put the `mov` files into it. )

And Aerial will use the cached `mov` if the file exists in `~/Downloads/AerialMovCache/`

## Features
* **Auto Load Latest Aerials:** Aerials are loaded directly from Apple, so you're never out of date.
* **Play Different Aerial On Each Display:** If you've got multiple monitors, this setting loads a different aerial for each of your displays.
* **Favorites:** You can choose to only have certain aerials play.
* **Preview:** Clicking on an aerial in the screen saver options previews that aerial for you.

## Compatibility
Aerial is written in Swift, which requires OS X Mavericks or above.

## Community
- **Find a bug?** [Open an issue](https://github.com/JohnCoates/Aerial/issues/new). Try to be as specific as possible.
- **Have a feature request** [Open an issue](https://github.com/JohnCoates/Aerial/issues/new). Tell me why this feature would be useful, and why you and others would want it.

## Contribute
I appreciate all pull requests. Caching hasn't been added yet.

## Changelog

- October 26th, 2015 - 1.1
  - Added thumbnail.
  - Added support for Mavericks.
  - Removes un-necessary logging.
  - Now shows error when installing on un-supported OS X version.
- October 26th, 2015 - 1.0: First release.

## License
[MIT License](https://raw.githubusercontent.com/JohnCoates/Aerial/master/LICENSE)
