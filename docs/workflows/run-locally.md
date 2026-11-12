# Run locally

Requirements: a Mac with Xcode 27 or later, and XcodeGen (`brew install xcodegen`).

## Run the logic tests

No simulator or device needed.

```bash
swift test --package-path JimakuCore
```

## Generate the Xcode project

The `.xcodeproj` is generated and not committed. Run this after cloning and after any change to `project.yml`.

```bash
xcodegen generate
```

## Build and run in the simulator

An iOS simulator runtime must be installed (`xcodebuild -downloadPlatform iOS`).

```bash
xcodebuild -project Jimaku.xcodeproj -scheme Jimaku -destination 'generic/platform=iOS Simulator' build
```

Or open `Jimaku.xcodeproj` in Xcode, pick a simulator, and press Run.

Screen broadcast, Picture in Picture, and background execution are not verified in the simulator. See `docs/conventions/write-the-failing-test-before-the-code.md`.

## Run on your own device

Create `JimakuApp/Signing.xcconfig.local` (gitignored) with your own values, then run `xcodegen generate` again:

```
DEVELOPMENT_TEAM = YOURTEAMID
JIMAKU_BUNDLE_PREFIX = com.yourname
```

Then select your device in Xcode and press Run.
