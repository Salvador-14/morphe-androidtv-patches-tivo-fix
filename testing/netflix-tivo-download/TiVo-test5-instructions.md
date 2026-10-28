# Netflix TiVo test5

Experimental startup-timing test for TiVo Stream 4K, Android 12, Netflix
13.0.1 build 25028. Playback must still be tested on the device.

Test5 prioritizes the current V3 ad patterns during startup so the old fallback
searches do not block the next attempt. It preserves test3's native crash fix,
Gadget configuration, and optional settings. The old per-scan diagnostics are
removed; the script logs `TIVO-TEST5` and the startup priority/patch timing instead.

## Install with ADB

Test5 has a **new signing key**. Moving from test3 to test5 requires a fresh
installation and deletes the clone's local settings and sign-in state. This data
deletion was accepted for this test. Keep the stock Netflix app installed.

Extract the test5 download, open a terminal in its directory, and run:

```sh
adb uninstall com.netflix.ninja.clone
adb install Netflix-TiVo-test5.apk
```

If the uninstall reports that the clone is not installed, continue with install.
Open Netflix and sign in again if prompted. The package remains
`com.netflix.ninja.clone`; the app label remains Netflix.

Keep the separate **signing backup ZIP** for future tests. Its key permits later
test builds to update this installation using `adb install -r` without deleting
its data. The signing key is not included in the APK download ZIP.

## Test and capture logs

After sign-in, start a capture in one terminal:

```sh
adb logcat -b main -b system -b crash -v threadtime -T 1 > tivo-test5-log.txt
```

In a second terminal, stop only the clone, then open it normally on the TV:

```sh
adb shell am force-stop com.netflix.ninja.clone
```

Repeat at least five fresh launches. Start the same known ad-supported title
promptly after opening the app; also try one slower launch. Check preroll,
seeking across a known midroll, and a second title without restarting. Note
which attempts actually play ads. Stop log capture with Ctrl+C when finished.

The log should contain `TIVO-TEST5`, `TIVO STARTUP: selective V3 priority enabled`,
and patch timing such as `fastMASTER: applied ... at +...ms`. Successful memory
write logs alone do not establish successful ad blocking. Keep the full capture
if ads remain or a crash occurs.

## Rebuild from this download kit

Use the included README.md and Build-Test5.cmd (Windows) or build_test5.py.
They reconstruct the already signed test5 APK from your original test3 APK.
