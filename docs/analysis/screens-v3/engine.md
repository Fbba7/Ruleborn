# The engine move v3.5 decided, measured (written by the lead, not a reader)

v3.5 pins Godot 4.7.2-stable with godot-rust v0.5.5 built for the 4.7 API (§24's engine row, §24.7, §26.6, §26.8, §32.8 brief 39), and §26.6's spike now also proves the store builds: Xcode 26 with the iOS 26 SDK (Apple, from 28 April 2026) and Android API level 36 (Google Play, from 31 August 2026, extension to 1 November 2026).

## What was measured on 7–8 October 2026, in a copy of the repository

- Godot 4.7.2-stable for Linux downloads from GitHub releases (`Godot_v4.7.2-stable_linux.x86_64.zip`, 78 MB) and runs headless: `4.7.2.stable.official.ed1daf0bf`.
- `client/ext` already pins `godot = "=0.5.5"`. Changing its feature from `api-4-5` to `api-4-7` builds offline from the local cargo registry (`godot-bindings-0.5.5` carries `api-4-6` and `api-4-7`); release build 4 min. The extension reports `API v4.7.stable.official, runtime v4.7.2.stable.official`.
- With `config/features=PackedStringArray("4.7")` and the extension rebuilt, `python3 client/status.py` on Godot 4.7.2 failed on one thing: 4.7 moved the screen-reader live-region constants from `DisplayServer` to a new `AccessibilityServer` singleton, so `client/scripts/ui.gd:138` (`DisplayServer.LIVE_OFF`) and `:321` (`DisplayServer.LIVE_ASSERTIVE` / `LIVE_POLITE`) are parse errors under warnings-as-errors, and every script that preloads `ui.gd` failed with them. Replacing those three constants with `AccessibilityServer.LIVE_*` and re-running: **100 of 100 client tests pass** on 4.7.2, the server-backed ones included.
- `client/scripts/settings.gd:40,42` still call `DisplayServer.accessibility_should_increase_contrast()` and `accessibility_should_reduce_animation()`; they compile and run on 4.7.2 (no warning raised under the test run). Whether 4.7 deprecates them in favour of `AccessibilityServer` should be checked against the 4.7 class reference when the move is made, and moved with the constants if so.

## What the move is, as a task

1. `client/project.godot`: features "4.7". `client/build.sh`: `version="4.7.2-stable"`. `client/ruleborn.gdextension`: `compatibility_minimum = 4.7`. `client/ext/Cargo.toml`: `api-4-7`.
2. `client/scripts/ui.gd`: the three live-region constants to `AccessibilityServer`.
3. `client/export.sh`: templates `4.7.2.stable`, from `Godot_v4.7.2-stable_export_templates.tpz` — **1.28 GB**, against 4.5's; the check still runs the Android export with the pack check.
4. `client/export_presets.cfg`: `gradle_build/target_sdk` is empty today (Godot's default); set it to 36 explicitly so Play's rule is a checked fact, and keep `min_sdk` at the engine's floor. The iPhone preset's `min_ios_version` stays 15.0; building with Xcode 26 and the iOS 26 SDK is a Mac step (TC.3, yours).
5. Documentation that says 4.5: `README.md:9,106,178`, `client/README.md:3,15,16,91,282`, `tools/roadmap.py:891,941`, `tools/privacy_manifest.py:10`. The register's prose about 4.5 is history and stays.
6. Proof: `python3 client/status.py` (100 of 100), the five golden replays agreeing at every second on the replay screen (part of the suite), `bash client/export.sh check` with the new templates, gdlint clean.

## Risks

- The 1.28 GB template download is the slowest step; the disk allowance here has room (16 GB free).
- `dl.google.com` is still refused by this environment's network policy, so the Android SDK and NDK (for an actual APK on API 36) are still yours to allow, as TC.3 already says. Nothing about 4.7 changes that.
- godot-rust's mobile support is still experimental (§24.7); the phone half of the spike (T3.1) is unchanged by the move and still needs devices.
