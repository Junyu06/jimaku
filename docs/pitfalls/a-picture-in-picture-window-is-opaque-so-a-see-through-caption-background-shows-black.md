# A Picture in Picture window is opaque, so a see-through caption background shows black

The frames the app draws can carry transparency, and the layer that shows them honors it: inside the app, a caption background drawn at 35 percent let the white card behind the preview show through. The floating window did not. In an iPad simulator (iOS 27.0) the system put the layer on a black backing of its own, so a more transparent background only looked blacker there, and nothing of the app underneath was seen.

This was seen in the simulator only. A trial build was put on a physical iPad as well, and the owner dropped the request for a half-transparent window afterwards; what the window looked like there was not recorded.

So do not offer a background opacity for the floating window without first seeing, on a device, that it shows what is behind it. What can be changed is how much of the screen the window covers: its text size, its number of lines, and the size the reader pinches it to.
