![screencast](https://cloud.githubusercontent.com/assets/499192/10754100/c0e1cc4c-7c95-11e5-9d3b-842d3acc2fd5.gif)

## Aerial - Apple TV Aerial Views Screen Saver
Aerial is a Mac screen saver based on the new Apple TV screen saver that displays the aerial movies Apple shot over New York, San Francisco, Hawaii, China, etc.

Aerial is completely open source, so feel free to contribute to its development!  

[![Github All Releases](https://img.shields.io/github/downloads/johncoates/aerial/total.svg?maxAge=2592000)]()
[![GitHub contributors](https://img.shields.io/github/contributors/johncoates/aerial.svg?maxAge=2592000)]()
[![Build Status](https://travis-ci.org/JohnCoates/Aerial.svg?branch=master)](https://travis-ci.org/JohnCoates/Aerial)
[![codebeat badge](https://codebeat.co/badges/cefd1672-5501-4b79-8d08-c2121cdbc9ed)](https://codebeat.co/projects/github-com-johncoates-aerial-e1c8873e-7a9f-4c74-9e50-0380add2478a)
[![Code Climate](https://codeclimate.com/github/JohnCoates/Aerial/badges/gpa.svg)](https://codeclimate.com/github/JohnCoates/Aerial)
[![codecov](https://codecov.io/gh/JohnCoates/Aerial/branch/master/graph/badge.svg)](https://codecov.io/gh/JohnCoates/Aerial)

###### Windows user? Try [cDima/Aerial](https://github.com/cDima/Aerial/)

#### Coded with Love by John Coates

[![Twitter](http://i.imgur.com/KzOiue1.png)](http://twitter.com/punksomething)
[![Email](http://i.imgur.com/FvDZudR.png)](mailto:john@johncoates.me)

## Installation

1. [Click here to Download](https://github.com/JohnCoates/Aerial/releases/download/v1.2/Aerial.zip)
2. Unzip the downloaded file.
3. Open **Aerial.saver** and confirm installation.

If Aerial.saver could not be opened, place Aerial.saver in ~/Library/Screen Savers

## Setting Aerial as Your Screen Saver

1. Open System Preferences -> Desktop & Screen Saver -> Screen Saver
2. Choose Aerial and click on Screen Saver Options to select your settings.

![Screenshot](https://cloud.githubusercontent.com/assets/499192/10754102/c58cc076-7c95-11e5-9579-4275740ba339.png)

## Features
* **Auto Load Latest Aerials:** Aerials are loaded directly from Apple, so you're never out of date.
* **Play Different Aerial On Each Display:** If you've got multiple monitors, this setting loads a different aerial for each of your displays.
* **Favorites:** You can choose to only have certain aerials play.
* **Preview:** Clicking on an aerial in the screen saver options previews that aerial for you.

## Compatibility
Aerial is written in Swift, which requires OS X Mavericks or above.

## Community
- **Found a bug?** [Open an issue](https://github.com/JohnCoates/Aerial/issues/new). Try to be as specific as possible.
- **Have a feature request?** [Open an issue](https://github.com/JohnCoates/Aerial/issues/new). Tell me why this feature would be useful, and why you and others would want it.

## Contribute
I appreciate all pull requests. Caching hasn't been added yet.

## Brew Cask Support - Install Remotely
If you're looking to install Aerial across many systems, remotely, or simply from terminal I recommend [Brew Cask](http://caskroom.io/).

Issue the following terminal command: `brew cask install aerial`

## Troubleshooting

- Black screen / cannot stream: If you run a reverse firewall, such as Little Snitch or Hands Off!, be sure the application 'ScreenSaverEngine.app' is not being blocked access to *.phobos.apple.com.
- Black preview / cannot pre-download: If you run a reverse firewall, such as Little Snitch or Hands Off!, be sure the application 'System Preferences.app' is not being blocked access to *.phobos.apple.com.

## License
[MIT License](https://raw.githubusercontent.com/JohnCoates/Aerial/master/LICENSE)
