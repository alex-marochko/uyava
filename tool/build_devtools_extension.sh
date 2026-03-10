#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DEVTOOLS_PUBSPEC="$REPO_ROOT/packages/uyava_devtools_extension/pubspec.yaml"
DEVTOOLS_CONFIG="$REPO_ROOT/packages/uyava/extension/devtools/config.yaml"
DEVTOOLS_VERSION="$(awk '/^version:[[:space:]]*/ {print $2; exit}' "$DEVTOOLS_PUBSPEC")"
if [[ -z "${DEVTOOLS_VERSION:-}" ]]; then
  echo "Failed to read version from $DEVTOOLS_PUBSPEC" >&2
  exit 1
fi

tmp_config="$(mktemp)"
awk -v version="$DEVTOOLS_VERSION" '
BEGIN { updated = 0 }
{
  if (!updated && $0 ~ /^version:[[:space:]]*/) {
    print "version: " version
    updated = 1
    next
  }
  print
}
END {
  if (!updated) {
    print "Failed to find \"version:\" field in extension config.yaml" > "/dev/stderr"
    exit 1
  }
}
' "$DEVTOOLS_CONFIG" > "$tmp_config"
mv "$tmp_config" "$DEVTOOLS_CONFIG"
echo "Synced DevTools extension manifest version to $DEVTOOLS_VERSION"

# Regenerate version constants before building so diagnostics stay accurate.
(cd "$REPO_ROOT" && dart run tool/generate_extension_versions.dart devtools)

cd "$REPO_ROOT/packages/uyava_devtools_extension"
flutter pub run devtools_extensions build_and_copy --source=. --dest=../uyava/extension/devtools
