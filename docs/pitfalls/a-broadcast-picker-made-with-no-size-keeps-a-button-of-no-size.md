# A broadcast picker made with no size keeps a button of no size

`RPSystemBroadcastPickerView` holds one `UIButton` that follows the picker's size through its autoresizing mask. A picker made with a frame of zero width and height and given its real frame afterwards leaves that button with a frame of no width, no height, and an infinite origin. The picker still takes the touch and the button never does. Sending the button the event in code still fires its action, which hides the fault: what the app does for the user looks right, and the same control under the user's finger does nothing.

Seen 2026-11-23 in an iPad mini (A17 Pro) simulator on iOS 27.0, with a build that logged hit tests: taps on a picker stretched to 664 by 50 points reached the picker and not its button, whose frame was `(inf, inf, 0, 0)`. Made at 44 by 44 points and with the button's frame set to the picker's bounds at each layout, taps 15 points from either end reached the button and fired its action. Not seen on a device.

What to do: make the picker with a frame that has a size, and when stretching it, set its button's frame as well. Check a tap by what the button receives, not by the sheet, which the simulator never shows.
