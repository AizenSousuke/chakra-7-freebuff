# Chainfall

A falling number-chain puzzle built in **Godot 4.7.2** with **GDScript**, for
Windows, Linux, Android and the web (single-threaded WebGL 2 export).

## Rules

- A piece is a **domino of two numbers**, 1-7. The first block is the pivot:
  rotation swings the second block around it like a clock, so a piece can face
  right, down, left or up.
- Two orthogonally adjacent numbers that differ by exactly one are *linked*.
- A linked path clears when it covers a whole sequence:
  - `1-2-3-4-5-6-7`
  - `7-6-5-4-3-2-1`
  - `1-2-3-4-5-6-7-6-5-4-3-2-1` (and the mirrored `7-1-7`)
- Only the cells on the chain clear; the rest drops and can cascade.
- Partial runs stay on the board — extend them later.
- Numbers that are one step apart are joined by a connector bar, so runs that
  are already on the board are visible at a glance.
- Every **7th piece** is a **star block**: a single cell that falls and drops
  like any other piece (no ghost preview). When it lands it deletes the whole
  joined group it is touching — bridging two groups clears both — for 150 points
  per removed cell. Landing on bare floor with nothing joined makes it fizzle.

Scoring: 700 for a 7-chain, 2100 for a 13-chain, multiplied by level and by
cascade depth. Clearing chains levels up the game and speeds up gravity.

## Controls

| Action | Keyboard | Touch |
| --- | --- | --- |
| Move | Left/Right or A/D | drag, or `<` `>` buttons |
| Rotate clockwise | X or Up | tap the board, or `CW` |
| Rotate anticlockwise | Z | `CCW` |
| Soft drop | Down / S | drag down, or `DROP` button |
| Hard drop | Space | `DROP` button |
| Pause | P / Esc | `II` button |
| Restart | R | tap the game-over panel |

## Build

```bash
tools/setup_godot.sh     # Godot 4.7.2 + export templates (outside the repo)
tools/export.sh          # web, linux, windows (+ android APK when set up)
```

Run from the editor:

```bash
godot --path .            # or open project.godot in the Godot editor
```

Rule tests, including chain detection and gravity:

```bash
godot --headless --path . --script tests/test_rules.gd
```

## Android

APK export needs JDK 17 and the Android SDK, kept outside the repo. Point Godot
at them in **Editor Settings → Export → Android**, and create a debug keystore:

```bash
keytool -genkeypair -keystore ~/.local/share/godot/keystores/debug.keystore \
  -storepass android -alias androiddebugkey -keypass android \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -dname "CN=Android Debug,O=Android,C=US"

godot --headless --path . --export-debug "Android" build/android/Chainfall-debug.apk
```

The APK is signed with that debug key, targets API 36 (min API 24) and ships
arm64 only. Change `package/unique_name` in `export_presets.cfg` before
publishing to Google Play, and enable `architectures/armeabi-v7a` for older
32-bit devices.

## Web hosting note

The exported web build is ~40 MB of WebAssembly, because the engine itself is
most of it. Cloudflare Pages/Workers rejects any single file over 25 MiB, so
serve `build/web/` from a host without that cap (itch.io, GitHub Pages, Netlify)
or precompress it. Play it locally with:

```bash
python3 -m http.server 8080 --directory build/web
```
