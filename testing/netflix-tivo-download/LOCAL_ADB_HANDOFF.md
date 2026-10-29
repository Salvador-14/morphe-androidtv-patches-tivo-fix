# Local Codex handoff: Netflix test5 on TiVo

Continue this investigation on the user's computer where ADB already works.
The previous session ran in a cloud environment with no route to the TV. A local
session has been selected, but no TV connection, installation, or playback test
has yet been performed by that cloud session.

## Goal and agreed scope

Install the verified test5 APK on the user's TiVo, collect logs, and test whether
ad blocking works consistently across fresh launches. The user authorized
uninstalling/reinstalling the Netflix clone and accepted losing its local app
data for the move from test3 to test5. Keep stock Netflix installed: only
`com.netflix.ninja.clone` is the test package. The user can choose and play titles
and report visible ads; coordinate playback with them during testing.

Use the selected local folder and the existing ADB installation. Ask for a
missing local APK path or TV connection endpoint if necessary. Do not assume
that the old cloud workspace paths or its files exist on this computer.

## Target and candidate

- TiVo Stream 4K, model SEI400TV, Android 12 / SC/1272, ARM32.
- Netflix 13.0.1 build 25028, package `com.netflix.ninja.clone`.
- Activity verified in the APK: `com.netflix.ninja.MainActivity`.
- This branch contains the download kit. The source fix has not been merged
  into `main`; use the verified APK or this kit for the device test.

Download kit:

https://github.com/Salvador-14/morphe-androidtv-patches-tivo-fix/raw/refs/heads/tivo-test5-download/testing/netflix-tivo-download/Netflix-TiVo-test5-rebuild-kit.zip

Kit ZIP SHA-256:
`63730878ff2d9b11cf572101a31485bbdaf628b684e2e718fc67ab15c16d27fa`

If the user already has test5, verify its hash. Otherwise extract the kit, inspect
its helpers, and run `Build-Test5.ps1 -InputApk <original-test3.apk>` or
`python build_test5.py <original-test3.apk>`. Both helpers were tested and
reconstructed the exact signed APK. They reject the wrong input and refuse to
replace an existing output. No Android build tools or signing key are required.

| File | SHA-256 |
| --- | --- |
| Required original test3 APK | `f1125b8a415ed6bc78c330f20ec1759b593d1a7252071799e53f532ccdc2966d` |
| Signed test5 APK | `878f427dc765b2e2186d88e39fd0e079aaed76ee760c4191de77e08d690414e1` |

Test5 uses a different signing key from test3. Its certificate SHA-256 is
`a81c216c9b46bf3e0d1cf14a87c75338c504def7813dace6af45366e862be5f5`.
The private signing key is not in GitHub or the kit; it is unnecessary for
installing this already signed APK. Do not re-sign it or create another key.

## Connect and install

1. Locate ADB and run `adb devices -l`. If the TV is already connected, use its
   existing transport. If no TV is listed, ask for its ADB endpoint or existing
   connection command. A pending ADB authorization prompt must be accepted by
   the user on the TV.
2. Confirm the target with read-only properties such as
   `adb -s <serial> shell getprop ro.product.model` and Android version. If
   multiple devices are listed, resolve the target before changing any package.
   Include `-s <serial>` on all device commands.
3. Verify the local test5 APK hash **before** uninstalling anything. Inspect the
   installed clone and preserve its identity/version details in the test notes.
   Both test3 and test5 have version code 25028; that alone cannot distinguish
   them. An APK hash, signing certificate, or startup marker can distinguish them.
4. For the accepted fresh installation from test3:

   ```sh
   adb -s <serial> uninstall com.netflix.ninja.clone
   adb -s <serial> install <path-to-Netflix-TiVo-test5.apk>
   ```

   If the clone is absent, just install. If the same test5 build is already
   installed, proceed to testing without unnecessarily deleting its data again.
   Have the user sign in on the TV if needed.

## Run and record device trials

Create a local results folder. Capture full main/system/crash logs to a separate
file for each trial, using a retained process/session so capture can be stopped
cleanly. Start capture **before** stopping and launching the clone:

```sh
adb -s <serial> logcat -b main -b system -b crash -v threadtime -T 1
adb -s <serial> shell am force-stop com.netflix.ninja.clone
adb -s <serial> shell am start -n com.netflix.ninja.clone/com.netflix.ninja.MainActivity
```

Redirect the first command to the trial's log file; it runs concurrently with
the other commands. Preserve raw logs locally rather than filtering the only
copy to the KILL tag. Do not clear system logs as a prerequisite.

Ask the user to start the same known ad-supported title promptly after launch
and report whether preroll ads appear. Try at least five fresh launches, plus a
slower profile-selection launch, a seek across a known midroll, and a second
title in the same process. Force-stopping the clone is sufficient between fresh
launch trials; reinstalling is not needed each time. Coordinate restarts so a
trial is not interrupted before the user has reported its outcome.

ADB remote-key input can help navigate, but Netflix may expose little useful UI
hierarchy and protected video may be black in screenshots. Use the user's
observations to establish whether ads played; command success or a memory-write
log does not establish ad-free playback.

Record each trial's title, quick/slow launch, approximate playback-start time,
preroll/midroll outcome, crashes, and log filename. Check for `TIVO-TEST5`,
`TIVO STARTUP: selective V3 priority enabled`, V3 patch/readback logs,
`fastMASTER: applied ... at +...ms`, and `apply DONE`. A failure needs the complete
log and the user's observed outcome, not repeated app kills until one run works.
Keep logs local unless the user asks to upload them; do not publish them to the
GitHub download branch automatically.

## Investigation context

The old startup crash is already fixed. Test5 preserves test3's native Gadget
and configuration byte for byte. Its only changed APK content entry is
`lib/armeabi-v7a/libgadget.script.so` (APK signing data also changes).

In an earlier failing test3 log, legacy searches blocked the single script
thread for 16.303 seconds. The V3 MASTER patch landed at +20.461 seconds while
clone playback was already reported at +18.943 seconds. In the working capture,
MASTER landed at +16.395 seconds and playback was reported at +27.827 seconds.
This supports a startup timing race; it does not prove V8 compilation timing or
establish timing as the only possible cause.

Test5 prioritizes V3 for up to 60 seconds, deferring heavy legacy/optional scans
until MASTER succeeds or the window expires. Existing pattern matches and
memory edits are retained. The old per-scan diagnostics are removed, which also
reduces logging overhead. All existing optional settings stay off. Five host
scheduler tests, binary-guard checks, APK signatures, ZIP integrity, alignment,
and script syntax passed. Device playback remains unverified.

Background:
- https://github.com/ajstrick81/morphe-androidtv-patches/issues/241
- https://chatgpt.com/share/6ad7da89-9ffc-83e8-ac0c-1bf1484cb385
