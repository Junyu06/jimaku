# Run locally

Requirements: a Mac with Xcode 27 or later, and XcodeGen (`brew install xcodegen`).

## Run the logic tests

No simulator or device needed.

```bash
swift test --package-path JimakuCore
```

## Generate the Xcode project

The `.xcodeproj`, the `Info.plist` files, and the `.entitlements` files are generated from `project.yml` and not committed. Run this after cloning and after any change to `project.yml`.

```bash
xcodegen generate
```

## Build and run in the simulator

An iOS simulator runtime must be installed (`xcodebuild -downloadPlatform iOS`).

```bash
xcodebuild -project Jimaku.xcodeproj -scheme Jimaku -destination 'generic/platform=iOS Simulator' build
```

Or open `Jimaku.xcodeproj` in Xcode, pick a simulator, and press Run.

In the simulator a stand-in writes a tone into the shared audio ring in place of the broadcast extension. To look at the start page without it, launch with `-simulatedRecording off` (no broadcast) or `-simulatedRecording silent` (a broadcast that hands over no sound). After quitting a run that wrote the tone, wait two seconds before a silent one, or its first moments still count as sound:

```bash
xcrun simctl launch booted <bundle identifier> -simulatedRecording off
```

To see the interface in English or in Chinese whatever the simulator's language, launch with `-AppleLanguages "(en)"` or `-AppleLanguages "(zh-Hans)"`.

The first tap on Start shows a page that says why the recording is needed, once for each installed app. To see it again, or to skip it, launch with `-recordingExplanationRead NO` or `-recordingExplanationRead YES`.

Screen broadcast, Picture in Picture, and background execution are not verified in the simulator. See `docs/conventions/write-the-failing-test-before-the-code.md`.

## Run on your own device

Create `JimakuApp/Signing.xcconfig.local` (gitignored) with your own values, then run `xcodegen generate` again:

```
DEVELOPMENT_TEAM = YOURTEAMID
JIMAKU_BUNDLE_PREFIX = com.yourname
```

Then select your device in Xcode and press Run.

The app and its broadcast extension share an App Group named `group.<JIMAKU_BUNDLE_PREFIX>.jimaku`. With automatic signing, Xcode registers it for your team on the first build.
