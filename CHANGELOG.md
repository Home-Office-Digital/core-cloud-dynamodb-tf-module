# Changelog

All notable changes to this project will be documented in this file. This will provide a record of all notable module updates with each new release. Semantic versioning (https://semver.org/) must be adhered to for all Core Cloud modules.

## [Unreleased]

### Changed

- CI: switched Terraform validation job to reusable standard pipeline (`core-cloud-workflow-terraform-actions/.github/workflows/standard-pipeline.yml`).
- CI: kept Checkov and Sonar scans as separate jobs.

## [1.0.0] - 2026-07-10

### Added

- Terraform native test suite under `tests/` (contracts, validation, security).
- Example coverage for `s3-import`.

### Changed

- Hardened module inputs with strongly typed table, index, import, and autoscaling objects.
- Optional object inputs now use `null` when unset.
- Updated wrappers/examples/docs alignment.

### Security

- Enabled point-in-time recovery and server-side encryption by default.
- Tightened validation behavior for safer module consumption.

### Breaking

- Input interface tightened; callers using loosely typed values may need updates.
- `null`-for-unset behavior is now explicit for typed object fields.

## [0.2.0] - 2026-02-20

### Changed

- Remediated Checkov findings.

## [0.0.1] - 2026-03-30

### Changed

- Removed Tivy after 2026 incident.

## [0.1.0] - 2025-01-10

### Added

- Initial cut of DynamoDB and resource policy module.
