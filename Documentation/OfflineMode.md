#  Offline Mode

If you want to use Aerial on a Mac behind a firewall or with no network access, the easiest way starting is to copy the content of the cache folder from another Mac where Aerial is already installed.

If that's not an option, you can manually recreate a cache folder by downloading files manually. This is how to download ALL videos. We recommend you start with the first one, consider the others optional : 

- Download and untar `https://sylvan.apple.com/Aerials/resources13.tar` (tvOS13 resources), rename the bundle to `TVIdleScreenStrings13.bundle` and the JSON to `tvos13.json`
- Optionnally, also download and untar `https://sylvan.apple.com/Aerials/resources.tar` (tvOS12 resources), rename the bundle to `TVIdleScreenStrings12.bundle` and the JSON to `tvos12.json`.
- Optionnally, also download and rename `https://sylvan.apple.com/Aerials/2x/entries.json` to `tvos11.json` (tvOS11 resources, also in 4K)
- Optionnally, also download and rename `http://a1.phobos.apple.com/us/r1000/000/Features/atv/AutumnResources/videos/entries.json` to `tvos10.json` (The original Aerials, in 1080p H.264 only)

You can then download the videos you want from the JSON files. In the 4K JSONs, you are looking for the `url-1080-H264` (1080p H.264, most compatible format), `url-1080-SDR` (1080p HEVC, better quality, requires a recent Mac for hardware decoding) or `url-4K-SDR` (4K HEVC). If you want to download the HDR versions, you can but please note that they will only play in Catalina, and a recent/fast Mac is heavily recommended. 

Please try to download the videos in the order mentionned (tvOS13 first) as videos routinely gets replaced with better versions. Because you will be downloading files manually, you will end up with many duplicate versions of the same videos. You can clean them up by going into the `Advanced` tab and use the `Trash old videos` feature there. You can find more information about the process [in this issue](https://github.com/JohnCoates/Aerial/issues/781#issuecomment-493677816)
