---
layout: ../../layouts/DocsLayout.astro
title: "Installation"
description: "Install the DevTools extension and the desktop app."
---

# Installation

Uyava ships as a DevTools extension and a desktop app. Both hosts read the same SDK events, so you can choose the workflow that fits your team.

If you want to keep terminal-based debugging habits, you can also mirror Uyava events to the app console during setup. See [SDK Integration](/docs/sdk-integration) for console logger options.

## DevTools extension (for users)

- Install it from the Flutter DevTools Extensions catalog when the public listing is available.
- Open DevTools while your app runs in debug or profile mode, then select the Uyava tab.

## DevTools extension (for contributors only)

If you work on the extension itself, build and copy it locally:

```bash
cd <repo>/.../uyava_devtools_extension
flutter pub run devtools_extensions build_and_copy \
  --source=. \
  --dest=<host-project>/extension/devtools
```

## Desktop app

- Download the installer from the Download page.
- Launch the app and paste the VM Service URI from your running Flutter app.
- The desktop host mirrors the DevTools UI but runs locally for better performance.

## IDE plugins (VS Code / Android Studio)

- Install IDE launchers from the marketplace links in [IDE Plugins](/docs/ide-plugins).
- Use them to open or attach Uyava Desktop with project context and VM Service URI.
- Keep Desktop installed locally; plugins are launchers, not replacements for Desktop.

Useful CLI shortcuts (desktop binary):

```bash
./uyava_desktop --vm-service-uri ws://127.0.0.1:xxxxx/ws?authToken=... --project-path /path/to/project
./uyava_desktop --focus-only
./uyava_desktop /path/to/log.uyava
```

## Desktop Pro

Desktop Pro unlocks advanced replay features but uses the same desktop installer. A license key enables Pro features in the running app.
