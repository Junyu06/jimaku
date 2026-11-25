# A tap on the broadcast control also presses another button in the same form row

The start page lays the system's broadcast control, a UIKit view, over a button it draws. With a second tappable thing in the same row of the form, a tap on the control fired the control's action and that second thing's action as well. It did so whether the second thing was a `Button` with the borderless style or a view with a tap gesture and a content shape of its own size.

Seen 2026-11-25 in an iPad mini (A17 Pro) simulator on iOS 27.0, with a build that logged the control's action: a tap 16 points from the left end of the wide button logged the action and also brought up the sheet that the line under the button opens. With that line in a form row of its own, the same taps logged the action and brought up nothing. Why the row passes the tap on was not found out. Not seen on a device.

What to do: keep the row that holds the broadcast control free of anything else that takes a tap. After a change near it, check by the log that a tap on the control does one thing.
