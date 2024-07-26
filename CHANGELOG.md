# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased
### Added
- preserve source information in release.json artifacts

### Changed
- try finding version in parent sources
- retrieve subpackage name from .package.name or .name field of the source

## [1.0.8] - 2024-07-25
### Added
- separator input to releaser and releaser-check workflows

## [1.0.7] - 2024-07-25
### Added
- aggregation of release.json artifacts as workflow outputs

## [1.0.6] - 2024-07-24
### Added
- publishing release.json from the release check workflow

## [1.0.5] - 2024-07-23
### Added
- support for rust to release workflows

### Changed
- disable cache in setup-go action by default

## [1.0.4] - 2024-07-15
### Added
- trigger Go workflows on merge queue events

### Fixed
- execute release nag only if preconditions are met

## [1.0.3] - 2024-06-21
### Added
- names to the steps in the Go test and check workflows

## [1.0.2] - 2024-05-21
### Changed
- allow using custom GitHub token in the releaser workflow

## [1.0.1] - 2024-03-21
### Changed
- rename pl-strflt/* to ipdxco/*

## [1.0.0] - 2024-03-21
### Changed
- updated codecov-action
- passed CODECOV_TOKEN secret to codecov-action explicitly (requires secrets to be set in the repository or organization settings)
- made template workflows inherit secrets from parent workflows

## [0.0.17] - 2024-01-13
### Changed
- updated GitHub Actions actions

## [0.0.16] - 2024-02-29
### Fixed
- install playwright dependencies before using it

## [0.0.15] - 2023-11-30
### Fixed
- revert adding permissions in JS release job (we cannot do that in a reusable workflow)

## [0.0.14] - 2023-11-30
### Changed
- permissions in JS release job

## [0.0.13] - 2023-11-01
### Added
- ability to ignore protoc version comments in `go generate` check

### Fixed
- coverage report uploads in JS reusable workflows

## [0.0.12] - 2023-08-23
### Changed
- fallback to `go get` in Go check workflow

## [0.0.11] - 2023-08-23
### Added
- allow skipping race detector in Go test workflow

## [0.0.10] - 2023-08-23
### Changed
- use bash as a default shell in reusable workflows that run on windows

## [0.0.9] - 2023-08-22
### Fixed
- started picking staticcheck version based on go version in Go check workflow

## [0.0.8] - 2023-08-15
### Added
- `go-version` input for Go check workflow

## [0.0.7] - 2023-08-13
### Fixed
- partially reverted setup-go action update

## [0.0.6] - 2023-08-12
### Changed
- updated versions of actions

## [0.0.5] - 2023-08-11
### Fixed
- Go installtion on self-hosted runners in Go test workflow

## [0.0.4] - 2023-08-11
### Fixed
- Go installtion on self-hosted runners in Go test workflow

## [0.0.3] - 2023-08-11
### Fixed
- Go installtion on self-hosted runners in Go test workflow

## [0.0.2] - 2023-08-10
### Fixed
- copy templates procedure
- Go release workflows
- Go update procedure
- JS test and release workflow

## [0.0.1] - 2023-08-07
### Added
- v0.0.1 of Unified CI 2.0
