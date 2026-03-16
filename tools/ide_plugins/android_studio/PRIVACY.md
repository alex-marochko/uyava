# Privacy Policy - Uyava Desktop Launcher Plugin

Last updated: 2026-03-10

This IntelliJ/Android Studio plugin performs local development tooling actions only.

## What the plugin does
- Detects a local Flutter/Dart VM Service URI from the running IDE session, environment variable, or user input.
- Resolves local executable paths (`flutter`, `uyava-desktop`) from environment variables and standard install locations.
- Launches the local Uyava Desktop executable with command-line arguments.

## Data handling
- The plugin itself does not send telemetry or analytics.
- The plugin itself does not upload project files, source code, or personal data to Uyava or third-party servers.
- The plugin does not implement its own remote API calls.
- The plugin does not persist collected values beyond normal in-memory runtime usage.

## Data that may be processed locally
- Project path.
- VM Service URI.
- Environment variables used for binary discovery:
  - `UYAVA_VM_SERVICE_URI`
  - `UYAVA_DESKTOP_PATH`
  - `UYAVA_FLUTTER_BIN`
  - `FLUTTER_ROOT`
  - `PATH`

## Third-party software
The plugin can start the separate Uyava Desktop application. Any data processing done by that application is governed by Uyava Desktop's own policies, not by this plugin.

## Contact
For questions, contact: support@uyava.io
