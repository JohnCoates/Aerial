#  Add your own videos to Aerial

Starting with version 1.5.0 of Aerial, you can now add your own videos to the playlilst. In order to do this, click "Custom Videos..." at the bottom of the menu:

![Capture d’écran 2019-05-24 à 17 13 22](https://user-images.githubusercontent.com/37544189/58338271-c090be80-7e47-11e9-833a-d70ada56232b.jpg)

This will open the "Manage Custom Videos" window. 

![Capture d’écran 2019-05-30 à 17 45 15](https://user-images.githubusercontent.com/37544189/58646170-24622e00-8305-11e9-9235-9e7960bdf95e.jpg)

Click the "Add folder" at the top of the window, and point it to a folder that contains videos. Aerial will scan that folder and show you the videos it found in the left panel. For long time users, a good way to try this is your `oldvideos` folder in your Aerial cache folder. 

## Folders and files

Aerial will scan your folder for video files, including subfolders. After scanning, all these video files will show up in the left column, grouped under the name of the folder you picked. 

![Capture d’écran 2019-05-24 à 17 13 44](https://user-images.githubusercontent.com/37544189/58338555-36952580-7e48-11e9-8f9b-4e69a48dc11b.jpg)

You can override that name here. This folder name will be used to categorize those videos in the playlist, akin to the classical "city/country" category you see for Aerial videos. If you use an existing name (for example "Los Angeles"), videos will be merged in the playlist. 

If you click a file, you'll get the asset editor: 

![Capture d’écran 2019-05-30 à 18 01 36](https://user-images.githubusercontent.com/37544189/58646171-24fac480-8305-11e9-98fd-c9ec7ef3a64c.jpg)


You can change the name of the video, whether it's a day or night video (by default every file is imported as day) and let's you add points of interests. Points of interests are the descriptions that are shown periodically on screens when videos play. The format is simple, a time in seconds, and the description you would like to appear. We highly recommend you leave at least 10 to 15 seconds between two points of interests. 

![Capture d’écran 2019-05-29 à 12 52 29](https://user-images.githubusercontent.com/37544189/58552781-8478a780-8213-11e9-99bc-2b55c75b6bd3.jpg)

## How is this stored ?

When you close the window, all the information will be saved in a `customvideos.json` file in your Aerial cache folder. The format is close to the tvOS12 format, and can be edited manually. 

## Video formats/containers supported

As of version 1.5.0, Aerial will only look for .mov or .mp4 files (if you would like to see another extension added, please let us know but keep reading first). Aerial uses Apple's AVFoundation framework to play videos. Long story short, in theory anything that QuickTime Player X can play, will work with Aerial. As of macOS Mojave, this means that some container formats such as mkv won't be supported.  
