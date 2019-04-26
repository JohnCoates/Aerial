# Translations of the community strings

Aerial features overlay descriptions of the main geographical features displayed in its videos. This is possible thanks to the collaboration and uninterested work of many. To best serve this international community we've a translation workflow defined that allows any person, even with no technical background to help translating the descriptions.

In the following sections we explain how to collaborate in the internationalization process both as a translator and as a developer.

## For translators

1. Contact [@glouel](https://github.com/glouel) or [@aitor](https://github.com/aitor) to get added to the Translators team at Lokalise.
2. Access the translations dashboard at https://lokalise.co/ and translate or update the existing strings to your language.
3. PROFIT!

## For developers

The translation workflow follows a pull mode, meaning that new strings will be defined in the Lokalise service and pulled into the project once they have been translated. The pulling process will be repeated after any changes has been made to the strings.

### Setting up the project

1. Contact [@glouel](https://github.com/glouel) or [@aitor](https://github.com/aitor) to get added to the Translators team at Lokalise.
2. Use the existing configuration example file to create your local configuration
   `cp lokalise.example.cfg lokalise.cfg`
3. In the created file update the `Token` string with your token. To get your token visit the section `API Tokens` at https://lokalise.co/profile

### Downloading/pulling translations

1. Install Lokalise CLI: https://docs.lokalise.co/api-and-cli/lokalise-cli-tool
2. Once the CLI has been installed you can pull the latest versions of each language with the following command:
   `lokalise --config lokalise.cfg d --type json --dest Resources/Community --unzip_to Resources/Community`
3. Commit and push the new `*.json` files to the repo.

## Supported languages & Kudos

The following people has helped to improve Aerial by providing translations and text corrections. Thanks everybody!

- English by [@SeanMSmith](https://github.com/SeanMSmith)
- Spanish by [@aitor](https://github.com/aitor)
- French by [@glouel](https://github.com/glouel)
- Polish by [@Soruk](https://github.com/Soruk)
- German by [@moeffju](https://github.com/moeffju)
- Hebrew by [@kaaspad](https://github.com/kaaspad)
- Arabic by [@kachikulu](https://github.com/kachikulu)
- Simplified Chinese by [@LinkeyLeo](https://github.com/LinkeyLeo)

## Sponsorship

![Lokalise logo](https://user-images.githubusercontent.com/4295/52958944-73f39e00-3395-11e9-9350-79bb7ee43d14.png)

[Lokalise](https://lokalise.co) supports Aerial and provides us with a free plan to make the translation of this project possible. Check it out for your next i18n project!
