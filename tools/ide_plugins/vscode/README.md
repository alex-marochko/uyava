# Uyava Desktop Launcher (VS Code)

VS Code extension that finds the active Flutter/Dart VM Service, passes the workspace path, and launches (or focuses) Uyava Desktop Pro. If the desktop app is missing, it shows an error instead of failing silently.

## Features
- Auto-detect VM Service via `flutter attach --machine --device-timeout` in the first workspace folder; falls back to a manual prompt.
- Passes `--vm-service-uri` and `--project-path` when launching Uyava Desktop Pro.
- Clear error if the desktop binary is not found (`UYAVA_DESKTOP_PATH` override, defaults per platform, or `uyava-desktop` in PATH).

## Build/Run locally
```bash
cd tools/ide_plugins/vscode
npm install
npm run compile   # produces dist/extension.js
# optional: vsce package   # requires vsce installed globally
```

Install the generated `.vsix` via **Extensions → ... → Install from VSIX** or run `code --install-extension uyava-desktop-*.vsix`.

Marketplace listing:
- https://marketplace.visualstudio.com/items?itemName=uyava.uyava-desktop-launcher

## Commands
- `Uyava: Launch/Attach Desktop` — auto-attach to a running Flutter/Dart app and open Uyava Desktop. If no VM Service is detected you’ll be asked to paste one or continue without attach.

## Defaults for locating Uyava Desktop
- `UYAVA_DESKTOP_PATH` if set.
- macOS: `/Applications/Uyava Desktop.app/Contents/MacOS/uyava_desktop`
- Windows: `C:\\Program Files\\Uyava Desktop\\UyavaDesktop.exe`, `C:\\Program Files (x86)\\Uyava Desktop\\UyavaDesktop.exe`
- Linux: `uyava-desktop` in `PATH` (falls back to `/usr/local/bin` and `/usr/bin`).
