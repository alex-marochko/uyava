# Uyava Desktop Launcher (Android Studio / IntelliJ)

One-click launcher that finds the active Flutter/Dart VM Service, passes the project path, and opens (or focuses) Uyava Desktop Pro. If the desktop app is missing, the action shows an in-IDE error instead of failing silently.

## Features
- Auto-detect VM Service via `flutter attach --machine --device-timeout` in the project root (no copy/paste; falls back to manual URI only if attach fails).
- Passes `--vm-service-uri` and `--project-path` to Uyava Desktop Pro.
- Graceful errors when the desktop binary is not found (env `UYAVA_DESKTOP_PATH` or default install paths/`uyava-desktop` in PATH).

## Build and install locally
1) Ensure Java 17+ and Gradle (or run `gradle wrapper` to generate `./gradlew`).  
2) From the repo root:
```bash
cd tools/ide_plugins/android_studio
./gradlew buildPlugin
```
3) Install the produced ZIP from `build/distributions/` via **Settings → Plugins → Install Plugin from Disk**.

Marketplace listing:
- https://plugins.jetbrains.com/search?search=Uyava%20Desktop%20Launcher

## Usage
- Command: `Tools → Uyava Desktop → Launch/Attach`.  
- If a VM Service isn’t found automatically, you’ll be prompted to paste one.  
- If the desktop app isn’t installed, you’ll see an error with the paths checked.

## Notes
- Requires the Flutter plugin in Android Studio/IntelliJ for `flutter attach` to succeed against running Flutter apps.
- Default desktop locations checked:  
  - macOS: `/Applications/Uyava Desktop.app/Contents/MacOS/uyava_desktop`  
  - Windows: `C:\\Program Files\\Uyava Desktop\\UyavaDesktop.exe`, `C:\\Program Files (x86)\\Uyava Desktop\\UyavaDesktop.exe`  
  - Linux: `uyava-desktop` in `PATH`
