---
area: language
status: not-run
---

# The settings list only the languages the device reports

- Input: on a device that can caption at least one pair of languages, open the app and open 说话的语言 (spoken language). If it lists only the language already chosen, the system may not have answered yet: close the menu and open it again, for up to a minute, until it lists more or the minute is over. Then note what it lists. For each language listed: choose it, start a session, play speech in that language, and stop.
- Expected result: every language listed starts a session whose original row shows the speech in that language. None of them ends in a message that speech recognition does not support the language.
- Property: a spoken language is offered only when this device can recognize it.

## Evidence

- Physical iPad: not run.
- Physical iPhone: not run.
- The simulator has no recognizer and no language packs to ask, and reports every language that can be spoken as recognized and every language pack as installed, so it cannot show a language being left out. The rules for what is offered given a report are covered by tests of JimakuCore (`LanguageSupport`): a language the device does not recognize, or that nothing can translate, is not offered, and when the device can do no pair at all a session does not start.
- Before the system has answered, the list holds only the language already chosen, whether or not the device can do it; that is why the steps wait. The language in use is always in the list, also when the device has answered that it cannot do it; a device that can do no pair at all is language-009.
- Which engines can be chosen for a pair is translation-008 (seen in a simulator) and translation-009 (a device that cannot run the model, not run).
