# A local signing file changes the bundle identifier of simulator builds

`JimakuApp/Signing.xcconfig.local` sets `JIMAKU_BUNDLE_PREFIX`, and it applies to every build, not only device builds. Once it exists, a simulator build is installed as `<your prefix>.jimaku`, next to any earlier `com.example.jimaku` install.

On 2026-11-12 this went unnoticed for half an hour: `simctl install` kept succeeding, while `simctl launch com.example.jimaku` kept opening the old build, so checks in the simulator were made against stale code.

After creating or changing the local signing file, launch the simulator build by the path of the built app, or by the new identifier, and remove the old install with `xcrun simctl uninstall <device> com.example.jimaku`.
