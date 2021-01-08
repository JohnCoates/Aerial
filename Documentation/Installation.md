# Installation, setup and uninstallation

## Installation instructions

Aerial now includes an auto-update mechanism using the [Sparkle open-source project](https://github.com/sparkle-project/Sparkle) (with EdDSA signatures). You will need to download it manually the first time :

### First Installation

_Rather install from Terminal? Look at the Brew Cask section below!_

1. Quit **System Preferences**.
2. [Download the latest release of Aerial.saver.zip](https://github.com/JohnCoates/Aerial/releases/latest). Alternatively, you can try the latest beta version [following this link](https://github.com/JohnCoates/Aerial/releases). 
3. Unzip the downloaded file (if you use Safari, it should already be done for you).
4. Double-click `Aerial.saver`; it will open in `System Preferences` > `Desktop & Screen Saver` and ask you if you want to install for all users or for your user only. Be aware that installing for all users will require a password at install **and each subsequent update, including auto-updates.**

If you see an error message saying "This app is damaged and can't be opened, you should move it to the trash", we suggest that **you download the file with Safari**, to prevent macOS Gatekeeper from throwing that error. Note that some outdated unzip software may cause that issue too.

**Important**: If you haven't quit System Preferences before installation, you will need to quit and reopen System Preferences after installation for Aerial to work correcly. This is a macOS bug. 

### Brew Cask Support

If you're looking to install Aerial across many systems, remotely, or simply from Terminal we recommend [Brew Cask](https://caskroom.github.io). 

Simply issue the following Terminal command:

```sh
brew install --cask aerial
```

To upgrade Aerial, run the following Terminal command:

```sh
brew upgrade --cask aerial
```

Please note that if you prefer using homebrew to update Aerial, we recommend you disable Sparkle auto updates in the `Updates`tab. 

**Warning** If you see that your settings aren't saved in Catalina, please check if this folder exists : You may need to create this folder manually : `~/Library/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/Library/Preferences/ByHost/`

You may need to manually create the ByHost folder manually as Catalina may not do so for you.

## Setting Aerial as Your Screen Saver

1. Open `System Preferences` -> `Desktop & Screen Saver` -> `Screen Saver`
2. Choose Aerial and click on `Screen Saver Options` to select your settings.

![screen shot 2018-10-29 at 13 17 23](https://user-images.githubusercontent.com/37544189/47649971-1f76a980-db7f-11e8-97be-d1f90b943c9d.png)

## Uninstallation

There are three ways to uninstall Aerial from your Mac. However please first read the "Removing the cache" section below.

- Right-click on the Aerial screen saver in `System Preferences` and select `Delete "Aerial"`. This will uninstall the screen saver automatically.
- If you prefer, you can delete the files manually. macOS can store screen savers in two locations depending on your choices, `/Library/Screen Savers` (if you installed for All Users) and `/Users/YOURUSERNAME/Library/Screen Savers` (installed for your user only). Check both locations for a file called `Aerial.saver` and delete any copies you find.
- If you installed Aerial using Brew Cask, then enter the following command in a Terminal window to uninstall:

```sh
brew uninstall --cask aerial
```

# Removing the cache 

Aerial stores your videos in a local cache on your machine. It's location depends on the version of macOS you used, how you installed Aerial (for one user or multiple user) and when you first installed Aerial. You can find the location of the cache prior to uninstalling by going into Aerial's `Caches` tab.

Prior to macOS Catalina (10.15), the cache for multiple user was either :
- `/Library/Caches/Aerial` (long time users)
- `/Library/Application Support/Aerial` (if you installed for the first time after summer 2019)

Prior to macOS Catalina (10.15), the cache for a single user was either : 
- `~/Library/Caches/Aerial` (long time users)
- `~/Library/Application Support/Aerial` (if you installed for the first time after summer 2019)

Starting with macOS Catalina (10.15), each user has a cache in it's own sandbox at this location : 
- `~/Library/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/Library/Application Support/Aerial`

Finally, the preference file is located either at :
- `~/Library/Preferences/ByHost/com.JohnCoates.Aerial.{UUID}.plist` (before Catalina)
- `~/Library/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/Library/Preferences/ByHost/com.JohnCoates.Aerial.{UUID}.plist` (starting with Catalina)

