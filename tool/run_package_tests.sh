#!/usr/bin/env bash
set -euo pipefail

# Optional arguments
timeout_arg=""
while (($#)); do
  case "$1" in
    --timeout=*)
      timeout_arg="${1#--timeout=}"
      ;;
  esac
  shift || true
done

# Detect presence of unit and integration test suites.
has_unit_tests=false
if [ -d test ] && find test -name '*_test.dart' -print -quit | grep -q .; then
  has_unit_tests=true
fi

has_integration_tests=false
if [ -d integration_test ] \
  && find integration_test -name '*_test.dart' -print -quit | grep -q .; then
  has_integration_tests=true
fi

if [ "$has_unit_tests" = false ] && [ "$has_integration_tests" = false ]; then
  echo 'Skipping tests (no *_test.dart in test/ or integration_test/)'
  exit 0
fi

if grep -q "sdk: flutter" pubspec.yaml; then
  if [ "$has_unit_tests" = true ]; then
    if [ -n "$timeout_arg" ]; then
      flutter test --no-pub --timeout="$timeout_arg"
    else
      flutter test --no-pub
    fi
  fi
  if [ "$has_integration_tests" = true ]; then
    while IFS= read -r test_file; do
      [ -z "$test_file" ] && continue
      if [ -n "$timeout_arg" ]; then
        flutter test --no-pub --timeout="$timeout_arg" -d flutter-tester "$test_file"
      else
        flutter test --no-pub -d flutter-tester "$test_file"
      fi
    done < <(find integration_test -name '*_test.dart' -print | sort)
  fi
else
  if [ "$has_unit_tests" = true ]; then
    if [ -n "$timeout_arg" ]; then
      dart test --timeout="$timeout_arg"
    else
      dart test
    fi
  fi
  if [ "$has_integration_tests" = true ]; then
    while IFS= read -r test_file; do
      [ -z "$test_file" ] && continue
      if [ -n "$timeout_arg" ]; then
        dart test --timeout="$timeout_arg" "$test_file"
      else
        dart test "$test_file"
      fi
    done < <(find integration_test -name '*_test.dart' -print | sort)
  fi
fi
