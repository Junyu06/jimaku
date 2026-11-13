# A Picture in Picture window is opaque, so a see-through caption background shows black

The frames the app draws can carry transparency, and the layer that shows them honors it: inside the app, a caption background drawn at 35 percent let the white card behind the preview show through. The floating window does not. The system puts the layer on a black backing of its own, so a more transparent background only looks blacker there, and nothing of the app underneath is seen.

Seen in an iPad simulator (iOS 27.0) with a trial build. The owner then looked at the same trial build on a physical iPad and gave up the request for a half-transparent window; no screenshot of that was kept.

So do not offer a background opacity for the floating window. What can be changed is how much of the screen it covers: its text size, its number of lines, and the size the reader pinches it to.
