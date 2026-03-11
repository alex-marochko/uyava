# Releasing and Publishing (OSS)

This document describes how to publish Uyava OSS packages to pub.dev.

Current publishable packages:

- `uyava_protocol`
- `uyava_core`
- `uyava_ui`
- `uyava`

`uyava_devtools_extension` is internal (`publish_to: none`) and is not published
directly.

## Pre-Release Checklist

1. `main` is clean and up to date.
2. CI is green.
3. Package versions and changelogs are updated.
4. For `uyava`, extension assets are rebuilt and copied:

```bash
dart run melos run build_devtools_extension
```

5. Dry-run all publishable packages:

```bash
cd packages/uyava_protocol && dart pub publish --dry-run
cd ../uyava_core && dart pub publish --dry-run
cd ../uyava_ui && dart pub publish --dry-run
cd ../uyava && dart pub publish --dry-run
```

## Publish Order

Publish in dependency order:

1. `uyava_protocol`
2. `uyava_core`
3. `uyava_ui`
4. `uyava`

Commands:

```bash
cd packages/uyava_protocol && dart pub publish
cd ../uyava_core && dart pub publish
cd ../uyava_ui && dart pub publish
cd ../uyava && dart pub publish
```

Wait until each version appears on pub.dev before publishing dependents.

## Tagging Policy

Recommended for each publish wave:

- At least one annotated workspace tag (example: `oss-pub-initial`), or
- Per-package tags (example: `uyava-v0.2.1-beta.1`).

Example:

```bash
git tag -a oss-pub-initial -m "Initial pub.dev publish wave"
git push origin oss-pub-initial
```

## Publisher Ownership

If packages are published under the wrong owner account, transfer package
ownership to the target publisher in pub.dev admin settings.

## Post-Release Checks

1. Verify package pages and versions on pub.dev.
2. Verify dependency resolution (`flutter pub add uyava` in a clean sample app).
3. Confirm docs links and screenshots still render correctly.
