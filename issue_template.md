## Known Issues

Before logging an issue please check if one of the problems you are experiencing is mentioned here. If the issue you are experiencing isn't covered here, then please delete this content and tell us about the problem you are experiencing or the feature you'd like to request.

### "You cannot use the Aerial screen saver with this version of OS X." message

If you get a message saying `You cannot use the Aerial screen saver with this version of OS X. Please contact the vendor to get a newer version of the screen saver.` that is a known bug with macOS that was reported to Apple in April 2016 as [rdar://25569037](http://openradar.appspot.com/25569037). As of November 2017 the bug is still not fixed. To work around the bug:
* Select the Aerial screensaver in System Preferences
* Close System Preferences with Aerial selected
* Reopen System Preferences and the preview should work now

### Mac won't sleep with Aerial as screensaver

If your Mac won't sleep while Aerial is the selected screensaver, then you probably have an older version of Aerial installed. Download the latest verson of Aerial here: https://github.com/JohnCoates/Aerial/releases/ Make sure to check both locations for the old version, it can be installed to `/Library/Screen Savers` and `/User/YOURUSERNAME/Library/Screen Savers`.

### Corrupted playback

If you are getting corrupted playback when the screensaver starts then that is a new bug in macOS High Sierra. It appears to be a problem with the Intel drivers in High Sierra. As a workaround tick the "Show with clock" option as that seems to eliminate the corruption for the moment. Discussed extensively here: https://github.com/JohnCoates/Aerial/issues/377

### No playback

If you are getting a crossed out play icon instead of the preview or the videos just never seem to load, please check that a firewall or proxy isn't blocking the screensavers access to the videos. Trying the following two URLs in a web browser might show if they are blocked. If you are on a Macbook you can also try caching the videos on another network to test whether it is your network provider that is blocking access.
http://a1.phobos.apple.com/us/r1000/000/Features/atv/AutumnResources/videos/comp_GL_G004_C010_v03_6Mbps.mov
http://a1.v2.phobos.apple.com.edgesuite.net/us/r1000/000/Features/atv/AutumnResources/videos/comp_GL_G004_C010_v03_6Mbps.mov
