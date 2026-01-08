---
layout: ../../layouts/DocsLayout.astro
title: "Installation"
description: "Install the DevTools extension and the desktop app."
---

# Installation

Uyava ships as a DevTools extension and a desktop app. Both hosts read the same SDK events, so you can choose the workflow that fits your team.

## DevTools extension

- When published, install it from the Flutter DevTools Extensions catalog.
- During development, build it locally from the repo and copy into the host package:

```bash
(cd packages/uyava_devtools_extension && \
  flutter pub run devtools_extensions build_and_copy \
    --source=. \
    --dest=../uyava/extension/devtools)
```

Open DevTools while your app runs in debug or profile mode, then select the Uyava tab.

## Desktop app

- Download the installer from the Download page.
- Launch the app and paste the VM Service URI from your running Flutter app.
- The desktop host mirrors the DevTools UI but runs locally for better performance.

Useful CLI shortcuts (desktop):

```bash
./uyava_desktop --vm-service-uri ws://127.0.0.1:xxxxx/ws?authToken=... --project-path /path/to/project
./uyava_desktop --focus-only
./uyava_desktop /path/to/log.uyava
```

## Desktop Pro

Desktop Pro unlocks advanced replay features but uses the same desktop installer. A license key enables Pro features in the running app.
