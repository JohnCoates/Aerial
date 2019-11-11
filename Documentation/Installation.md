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

On very recent releases (less than a day), Chrome may complain that the file is uncommon and potentially dangerous. This warning will go away after a few hours/days, more information in our [troubleshooting section](Troubleshooting.md).

**Important**: If you haven't quit System Preferences before installation, you will need to quit and reopen System Preferences after installation for Aerial to work correcly. This is a macOS bug. 

### Brew Cask Support

If you're looking to install Aerial across many systems, remotely, or simply from Terminal we recommend [Brew Cask](https://caskroom.github.io). 

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

There are three ways to uninstall Aerial from your Mac.

- Right-click on the Aerial screen saver in `System Preferences` and select `Delete "Aerial"`. This will uninstall the screen saver automatically.
- If you prefer, you can delete the files manually. macOS can store screen savers in two locations depending on your choices, `/Library/Screen Savers` (if you installed for All Users) and `/Users/YOURUSERNAME/Library/Screen Savers` (installed for your user only). Check both locations for a file called `Aerial.saver` and delete any copies you find.
- If you installed Aerial using Brew Cask, then enter the following command in a Terminal window to uninstall:

```sh
brew cask uninstall aerial
```

You may also want to delete the folder `/Library/Caches/Aerial` (default Aerial cache folder on most systems, even if you installed for your user account only) or `/Users/YOURUSERNAME/Library/Caches/Aerial`. This is where Aerial stores the cached copies of the Aerial videos. The last thing, you may want to delete the preferences `plist`. The file is `/Users/YOURUSERNAME/Library/Preferences/ByHost/com.JohnCoates.Aerial.{UUID}.plist`.
