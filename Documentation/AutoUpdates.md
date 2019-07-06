#  About auto-updates

Starting with version 1.4.8, Aerial now includes the open source project [Sparkle](https://sparkle-project.org) to provide automatic updates. You can configure if and how you want this to work in the `Updates` tab:

![Capture d’écran 2019-05-30 à 11 45 55](https://user-images.githubusercontent.com/37544189/58624482-a5eb9900-82d0-11e9-8a93-0aeb71988802.jpg)

What you are seeing above are the out-of-the-box default. 

## Understanding the two settings

Because Aerial is "just" a screen saver (technically, a plugin to System Preferences), providing updates is slightly more involved and because of this, we have two, separate, automatic update mechanisms with two separate settings to control them:

- The first setting controls whether you want automatic updates or not. This check is done periodically (if 24 hours elapsed since last check), but *only* when the screen saver panel (the one you see in the screenshot) is open. When an update is available, you will see this window pop:

![Capture d’écran 2019-05-30 à 11 58 34](https://user-images.githubusercontent.com/37544189/58625280-6a51ce80-82d2-11e9-8dd0-a5ed92fa74f4.jpg)

You can then decide if you want to install or not, the checkbox controls whether you want this to be done automatically for you *for this specific mechanism*. 

- The second setting controls whether you want Aerial to update itself while the screen saver is running. Because most people don't fiddle everyday with their screen saver settings, we've added this secondary mechanism to Aerial so everyone can stay up to date. Unlike the first mechanism above, this one is silent, and having this option enabled will automatically install the latest update without prompting you. The check is periodic (if 24 hours elapsed since last check), and done when the screen saver starts. If an update is available, the screen saver will exit, install the update, and open system preferences with the new version of Aerial. Your system will go back to sleep eventually.  

While we recognize that the second mechanism is highly perfectible, this is the only workaround we've found with Sparkle to provide automatic updates while Aerial runs, or without having some sort of "helper" app always running on your system to check for updates. Unless you want to manualy manage your updates, we highly recommend you keep this checked!

## Beta updates

The third checkbox lets you opt-in to the beta updates. Beta releases are used to test fixes to reported issues, latest videos and new features. They are usually pretty stable. If you want those beta versions, you can enable this checkbox. Note that when a new non-beta release is available after the beta process, it will also be available in the beta track, so you are always up to date!

## What kind of network traffic does that entail? 

When a check happens, the auto update loads a [XML file from the GitHub repository](https://github.com/JohnCoates/Aerial/blob/master/appcast.xml) for the new updates. The updates are then downloaded from the GitHub repository's "Releases" section, the download link is included in the XML, they are always in the form of `https://github.com/JohnCoates/Aerial/releases/download/v1.5.0/Aerial.saver.zip` . 

While Sparkle optionally allows to [collect anonymous user data](https://sparkle-project.org/documentation/system-profiling/), we **do not** use this feature and **do not** collect any form of data whatshowever.

## Security?

Each update is signed with a private EdDSA key when a release is built by the maintainer ([glouel](https://github.com/glouel). The [appcast.xml](https://github.com/JohnCoates/Aerial/blob/master/appcast.xml) provides that signature (and file size, for example for 1.4.9 :  `sparkle:edSignature="5QFV0eqGRqCoZ8/TYbLXWOiVSifwNRUk4wuNFdjXJXpk/cRrceaTcs7SG168dawfOTpy9TOu283mb6WJGRQuDw==" length="5674805"` ) which will be checked against the public key bundled with Aerial. If the signature doesn't match, the update won't be installed. Each `Aerial.saver` is also signed with my ([glouel](https://github.com/glouel)) Apple ID certificate, which is also [checked by Sparkle](https://github.com/sparkle-project/Sparkle/issues/1283). Starting with 1.5.1 all Aerial builds are also notarized by Apple.

## Installed for all users and password prompt

If you installed the screen saver for all users the first time (instead of for your individual user), macOS prompted you at install for your administrator password. The same thing will happen for automatic updates with the two mechanisms. Because of this, with the "Auto update when screen saver runs" checked, you will get a password prompt from Aerial/Sparkle when waking up your system.

This is working as intended for macOS, if you are bothered by those prompt, consider reinstalling Aerial for your user account only. If you have multiple accounts, you can still install Aerial for each account, by default each will use the same shared cache for videos (in `/Library/Caches/Aerial/`).

## Homebrew and auto-updates

If you installed Aerial through Homebrew, you will get updates automatically from that channel. Note that because of the way brew cask works, it may take a few hours for the update to show, compared to the Sparkle auto-update. We recommend that you disable the built in auto-updates if you use Homebrew. 
