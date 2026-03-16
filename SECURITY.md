# Security Policy

## Supported Scope

This policy applies to the `oss` repository and its published packages.

## Reporting a Vulnerability

Please do not open a public GitHub issue for security vulnerabilities.

Use one of these channels:

1. GitHub Security Advisory ("Report a vulnerability") for this repository.
2. If advisory flow is unavailable, open a private maintainer contact request
   through repository owners and clearly mark it as a security report.

Include:

- affected package/version
- impact description
- reproduction steps or proof of concept
- suggested mitigation (if known)

## Disclosure Process

1. Report is triaged.
2. Fix is prepared privately when possible.
3. A patched release is published.
4. Public disclosure follows after fix availability.

## Secrets and Credentials

- Never commit secrets, API keys, tokens, private certificates, or credentials.
- Use GitHub Secrets/Variables for CI configuration.
- Rotate exposed credentials immediately if leakage is suspected.
