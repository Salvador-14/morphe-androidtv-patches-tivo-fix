# Netflix TiVo test5 download kit

This kit reconstructs the exact signed **Netflix-TiVo-test5.apk** from your
existing **Netflix-TiVo-test3.apk**. It contains a small binary update and local
helpers, rather than a full Netflix APK. The helper verifies the original APK,
applies the update, and verifies the complete result using SHA-256.

## Windows

1. Extract the entire kit ZIP into a folder.
2. Double-click **Build-Test5.cmd**.
3. In the file picker, select your original **Netflix-TiVo-test3.apk**.
4. Wait for **SUCCESS**. **Netflix-TiVo-test5.apk** appears beside the helper.

Windows PowerShell is sufficient; no Python, signing key, or Android build tools
are required. The `.cmd` launcher permits its bundled PowerShell script for that
process only; it does not change the machine's execution-policy setting.
The original test3 file is opened read-only. An existing output is never replaced.

If Windows policy prevents the helper from running, use the Python alternative
below. With PowerShell already open, you can also supply paths explicitly:

```powershell
.\Build-Test5.ps1 -InputApk "C:\path\Netflix-TiVo-test3.apk"
```

## Python alternative (Windows, macOS, Linux)

With Python 3 installed, run from the extracted folder:

```sh
python build_test5.py /path/to/Netflix-TiVo-test3.apk
```

Use `python3` instead of `python` if that is your system's command. The helper
uses the standard library only. `--output /path/to/new.apk` selects a new output
location. Both helpers work locally without network access.

## Install

Test5 uses a new signing key. The accepted fresh installation deletes the old
clone's local data, so you may need to sign in again. Keep stock Netflix installed.

```sh
adb uninstall com.netflix.ninja.clone
adb install Netflix-TiVo-test5.apk
```

Read **TiVo-test5-instructions.md** for the repeated-launch test and log capture.
Device playback testing remains pending. This test preserves the native crash
fix and prioritizes the current ad patterns during startup.

## Verification

Required original test3 APK SHA-256:

```text
f1125b8a415ed6bc78c330f20ec1759b593d1a7252071799e53f532ccdc2966d
```

Resulting signed test5 APK SHA-256:

```text
878f427dc765b2e2186d88e39fd0e079aaed76ee760c4191de77e08d690414e1
```

The delta copies unchanged byte ranges from test3 and supplies the changed ZIP
headers, ad script, and public APK signature block. The signing private key and
password are not part of the kit. SHA-256 verification establishes that the
result is byte-for-byte the already validated test5 APK, including its signature.
The payload is not an installable APK by itself.
