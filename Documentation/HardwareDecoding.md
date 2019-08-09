# About HEVC and hardware decoding, and HDR

Aerial uses Apple's [AVFoundation framework](https://developer.apple.com/documentation/avfoundation) to play the videos as your screen saver. When available, AVFoundation will use hardware decoding (from your CPU or your graphics card) to minimize the resources needed for video playback. You can find guidelines in the help button next to the `Preferred video format` setting. By default, Aerial uses 1080p H.264 videos which is the most compatible format. Please note that all 4K HEVC videos are encoded with the `Main10` profile, which may not be hardware accelerated by your machine, while some other HEVC videos (encoded in `Main` profile) will be.

While we wish to provide everyone with the best setting for their machine, the GVA framework from Apple doesn't let us distinguish HEVC `Main10` profile acceleration from general HEVC acceleration. Early feedback we gathered also seems to point that on machines with multiple decoding options (Intel QuickSync and AMD UVD), QuickSync will always be preferred (even if you "force" the discrete GPU use with an external monitor or via code, as of macOS Mojave).

These are our recommendations so far:

- Macs older than 2011 may lack H.264 acceleration.
- Macs with an Intel CPU (With iGPU) from the Sandy Bridge (2011) generation to Broadwell (Early 2015) should have H.264 hardware acceleration available.
- Late 2015 and 2016 Macs (Skylake and Kaby Lake) may only have partially accelerated HEVC decoding. We recommended you stick to 1080p H.264 on laptops. You may consider the HEVC format on desktops but understand that decoding may be CPU intensive and spin up your fans.
- Macs 2017 and up should have full HEVC acceleration (the 2017 12 inch Macbook being a notable exception, only having partially accelerated HEVC decoding).

You can easily check for yourself what to expect by opening a video in Quicktime (Use the `Show in Finder` option in the `Cache` tab to find the cached videos). In Activity Monitor, the AV Framework GVA process is called `VTDecoderXPCService`.

# About macOS versions

Because we use Apple's Framework, what is supported will depend on the version of macOS you use.
- You need at least macOS 10.13 to play HEVC videos
- You need at least macOS 10.15 to play HDR videos 

