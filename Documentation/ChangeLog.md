#  Aerial change log

## [1.5.0](https://github.com/JohnCoates/Aerial/releases/tag/v1.5.0) - May 31, 2019

- Completely rewritten multi monitor support. You can now enable and disable individual displays in the new Display tab:

![Capture d’écran 2019-05-29 à 14 44 01](https://user-images.githubusercontent.com/37544189/58558340-d116af80-8220-11e9-9081-696d805c1e29.jpg)

- New "Spanned" viewing mode. Selecting this mode will span an Aerial video on all your (selected) screens. You can even adjust margins:

![Capture d’écran 2019-05-29 à 14 43 52](https://user-images.githubusercontent.com/37544189/58558342-d116af80-8220-11e9-8bb0-8d26f1e1b6ed.jpg)

- Add your own videos to Aerial using the new Custom Videos features. You can add your own videos in the new video manager (found in the menu below the video list):

![Capture d’écran 2019-05-29 à 12 52 29](https://user-images.githubusercontent.com/37544189/58552781-8478a780-8213-11e9-99bc-2b55c75b6bd3.jpg)

You can find more [information here](CustomVideos.md).

- You can now remove a single video from cache by right clicking it.
- Sparkle updated to 1.21.3.
- And many bug fixes!

## [1.4.9](https://github.com/JohnCoates/Aerial/releases/tag/v1.4.9) - May 1, 2019

- Fix a crashing bug in 1.4.8 for homebrew users. 

## [1.4.8](https://github.com/JohnCoates/Aerial/releases/tag/v1.4.8) - April 30, 2019

- Add support for the 5 new 4K videos (January 25th update).
- Automatic updates through Sparkle.

![Capture d’écran 2019-04-30 à 18 31 20](https://user-images.githubusercontent.com/37544189/56977789-4afe3f00-6b76-11e9-9985-1ca1a1866d6b.jpg)

- Localization for community support in Arabic, Chinese Simplified, English, French, German, Hebrew, Polish and Spanish! Thanks to all the contributors. If you want to help, check here, we very much welcome new contributions !
- You can now skip an Aerial with the right arrow key.
- You can now save your favorite videos sets to enable them quickly (look for the bookmark icon below the video list).
- And many bug fixes!

## [1.4.6](https://github.com/JohnCoates/Aerial/releases/tag/v1.4.6) - December 28, 2018

- **25 extra videos now available in 4K:** Following the content updates from October 30th and December 5th, Aerial now includes 70 videos, 60 of which are also available in 4K. Aerial will periodically check for new videos, you can disable this feature in the `Cache` tab.

![screen shot 2018-10-29 at 13 21 05](https://user-images.githubusercontent.com/37544189/47649972-1f76a980-db7f-11e8-910b-1d5d50931ae2.png)

- **Show videos in Quicktime:** You can now right click a video to open it in Quicktime.
- **Remove video duplicates:** Aerial can now cleanup your old videos (They are periodically updated to fix colors, provide longer versions of previously existing videos, or upgraded to 4K). Go to the `Advanced` Tab and either move the files away or send them to the trash to reclaim free space. The `Move old videos` button will move the video files to a directory created within the Aerial cache called `oldvideos`, which will contain a dated directory within it. You can find them at `/Users/YOURUSERNAME/Library/Caches/Aerial/oldvideos/YYYY-MM-DD`

![capture d ecran 2018-12-13 a 15 06 49](https://user-images.githubusercontent.com/37544189/49943901-60394080-fee9-11e8-93b0-3cc68087b70e.png)


## [1.4.5](https://github.com/JohnCoates/Aerial/releases/tag/v1.4.5) - November 3, 2018

- **More battery controls:** Using Aerial on a Macbook ? You can now specify a different video format on battery mode if you wish, or simply video playback using the Power Saving mode (Aerial will show a blank screen and reduce screen brightness instead of showing videos).
- You can now show day/night videos based on Dark Mode.
- And many bug fixes!

## [1.4.4](https://github.com/JohnCoates/Aerial/releases/tag/v1.4.4) - October 29, 2018

- New sunset/sunrise dusk/dawn calculation modes from coordinates, Aerial can gather your location using your Mac's location service (you'll be asked for permission). Includes multiple calculations modes for dusk to better suite everyone's needs

![screen shot 2018-10-29 at 13 24 46](https://user-images.githubusercontent.com/37544189/47649974-1f76a980-db7f-11e8-8339-3f0424652b8c.png)

- Control brightness, Aerial can progressively dim the brightness of your screen when it plays. Includes extra options to only enable at night or on battery

![screen shot 2018-10-29 at 13 25 10](https://user-images.githubusercontent.com/37544189/47649975-200f4000-db7f-11e8-9e8b-f75c4a5ebde4.png)

- Add an option to define the margins from the border where descriptions should appear, changed the default for something more sensible
- And many bug fixes/ui tweaks!

## [1.4.3](https://github.com/JohnCoates/Aerial/releases/tag/v1.4.3) - October 23, 2018

- Fix a memory retain cycle while downloading or playing cached videos

## [1.4.2](https://github.com/JohnCoates/Aerial/releases/tag/v1.4.2) - October 23, 2018

- Community location description, with better descriptions on many of the older videos (english only for this version)
- Updated video names
- Added logging options in Advanced panel, with better error messages when something goes wrong
- You can now stop video downloads
- You can now disable seconds on clock
- We now have a retina(ish) thumbnail in System Preferences

## [1.4.1](https://github.com/JohnCoates/Aerial/releases/tag/v1.4.1) - October 16, 2018

- Better names for the videos
- New location information for "old" videos (London, SF, etc)
- You can now change the font/size of the location information displayed during videos
- New options for text display (custom message, same styled clock, etc)
- Add a "Main display only" option for multiple monitor setups

## [1.4.0](https://github.com/JohnCoates/Aerial/releases/tag/v1.4) - October 11, 2018

- Every Aerial video: From the very first Aerials in San Francisco to the new space videos shot from the ISS!
- 4K HEVC: With the launch of Apple TV 4K, many videos are now available in this format. Aerial will show you the best format available based on your preferences.
- Different videos based on time: Want to see night videos at night? You can either specify your sunset or sunrise time manually, or, if your Mac is compatible with Night Shift (see here for a list of compatible Mac), get those automatically (you do not need to enable Night Shift).
- Feeling Dark?: Aerial is now compatible with Dark Mode in macOS 10.14 Mojave, and can play night videos when Dark Mode is enabled.
- Descriptions: Wondering where an Aerial view was shot? Aerial can now tell you as they play.
- Full offline mode:: Behind a firewall? Just copy the cache folder from another Mac and you are all set. You can also disable all streaming.
Better cache management: You can now cache your favorite videos individually, no need to grab them all. Or just stream them as you go, they'll get cached automatically too.


## [1.2beta5](https://github.com/JohnCoates/Aerial/releases/tag/v1.2beta5) - December 28, 2016

- Latest beta from @JohnCoates

You can find more information about older versions and betas in the project [Release history](https://github.com/JohnCoates/Aerial/releases).
