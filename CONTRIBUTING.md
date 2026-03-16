# Contributing to Uyava OSS

Thanks for contributing.

This repository contains the open-source Uyava workspace (`packages/*`,
`examples/*`, `site/*`).

## Workflow

1. Create a feature/fix branch from `main`.
2. Keep each PR focused on one logical change.
3. Open a PR and wait for required CI checks to pass.
4. Merge to `main` only after review/validation.

Direct pushes to `main` are strongly discouraged (except urgent maintainer
hotfixes).

## Required Checks Before Merge

From repository root:

```bash
dart pub get
dart run melos run test
```

If your change affects the DevTools extension bundle shipped in `uyava`, run:

```bash
dart run melos run build_devtools_extension
```

If your change affects docs/site, ensure `site` build is healthy in CI.

## Cross-Platform Note

Some workspace scripts are Bash-based (for example
`tool/run_package_tests.sh`, `tool/build_devtools_extension.sh`).

On Windows, run these scripts through WSL or Git Bash.

## Docs and Changelog Expectations

- Public behavior/API changes must update docs in the same PR.
- Publishable packages should keep `CHANGELOG.md` in sync with version bumps.

## Commit and PR Hygiene

- Use clear commit messages (`feat:`, `fix:`, `docs:`, `chore:` patterns are
  recommended).
- Avoid unrelated formatting/noise in functional PRs.
- Never commit secrets, credentials, or private tokens.

## Releases

Release and pub.dev publish flow is documented in [RELEASING.md](./RELEASING.md).

## Security

Security reporting policy is documented in [SECURITY.md](./SECURITY.md).
