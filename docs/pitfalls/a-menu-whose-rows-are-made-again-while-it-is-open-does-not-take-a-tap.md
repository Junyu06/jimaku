# A menu whose rows are made again while it is open does not take a tap

Seen in an iPad mini (A17 Pro) simulator, iOS 27.0, on 2026-11-23. The choice of translation engine was a `Picker` whose rows came from a `ForEach` over a list worked out from the settings, written directly in the form of `StartView`. During a session that form is drawn again with every caption. The menu opened, and tapping a row in it did nothing, three times out of three: the menu stayed open and the engine did not change. The display-mode `Picker` next to it, whose two rows are written out, took its tap during the same session.

Moving the language and engine rows into a view of their own (`LanguageRows`), which reads only the settings and so is not drawn again when a caption arrives, made the same tap work.

What to do: a `Picker` whose rows are computed, and that must work while a session runs, goes in a view that does not read the transcript. Whether a device behaves like the simulator here was not checked.
