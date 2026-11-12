# The iPhone simulator does not support Picture in Picture

`AVPictureInPictureController.isPictureInPictureSupported()` returns `false` on iPhone simulators and `true` on iPad simulators (measured on the iOS 27.0 simulator runtime, iPhone 17 and iPad mini (A17 Pro), 2026-11-12).

So the floating caption window can be exercised in an iPad simulator but not in an iPhone simulator. In an iPhone simulator the app shows its "Picture in Picture is not supported" notice and the session does not start. That is expected there and says nothing about a real iPhone.

Do not conclude from an iPhone simulator run that the caption window is broken, and do not treat an iPad simulator run as proof for a physical device.
