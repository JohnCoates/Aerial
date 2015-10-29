![screencast](https://cloud.githubusercontent.com/assets/499192/10754100/c0e1cc4c-7c95-11e5-9d3b-842d3acc2fd5.gif)

## Aerial - Apple TV Aerial Views Screen Saver
Aerial is a Mac screen saver based on the new Apple TV screen saver that displays the aerial movies Apple shot over New York, San Francisco, Hawaii, China, etc.

Aerial is completely open source, so feel free to contribute to its development!

#### Coded with Love by John Coates

[![Twitter](http://i.imgur.com/KzOiue1.png)](http://twitter.com/punksomething)
[![Email](http://i.imgur.com/FvDZudR.png)](mailto:john@johncoates.me)

## To install:

1. [Click here to Download](https://github.com/yourtion/Aerial/releases/download/v1.2/Aerial.saver.zip)
2. Unzip the downloaded file.
3. Open **Aerial.saver** and confirm installation.

If Aerial.saver could not be opened, place Aerial.saver in ~/Library/Screen Savers

## To set Aerial as your Screen Saver:

1. Open System Preferences -> Desktop & Screen Saver -> Screen Saver
2. Choose Aerial and click on Screen Saver Options to select your settings.

![screenshot](https://cloud.githubusercontent.com/assets/1475301/10808988/883bd944-7e2c-11e5-87f6-63acaed11ad0.JPG)

## Features
* **Auto Load Latest Aerials:** Aerials are loaded directly from Apple, so you're never out of date.
* **Play Different Aerial On Each Display:** If you've got multiple monitors, this setting loads a different aerial for each of your displays.
* **Favorites:** You can choose to only have certain aerials play.
* **Preview:** Clicking on an aerial in the screen saver options previews that aerial for you.

## Manual Download Files And Add To CacheDirectory

Aerial will cache on-demand and you can add the mov file cache to CacheDirectory.

1. Download the `mov` files form [http://a1.phobos.apple.com/us/r1000/000/Features/atv/AutumnResources/videos/entries.json](http://a1.phobos.apple.com/us/r1000/000/Features/atv/AutumnResources/videos/entries.json) 

2. open System Preferences -> Desktop & Screen Saver -> Screen Saver. Choose Aerial and click on Screen Saver Options and click `OpenCacheDirectory ` and copy the file you download into it.

*Or just put the `mov` files into `~/Library/Caches/AerialMovCache/`.*

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
