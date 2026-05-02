# Changelog

All notable changes to this project will be documented in this file.

## [0.1.1] - 2026-05-02

### Added

- Added focused repository documentation for architecture, catalog synchronization, and release workflow.
- Added clearer source comments across the handwritten Ruby implementation.
- Added provenance headers to generated catalog files.
- Added a `Makefile` with common development and release commands.

### Changed

- Improved the README with release guidance, Makefile usage, and publishing instructions.
- Updated development dependencies:
  - `minitest` to `6.0.6`
  - `rake` to `13.4.2`
- Refined the QR payload builder implementation to keep concatenation explicit and comment-safe.

### Verified

- Confirmed the full test suite passes.
- Confirmed the gem builds successfully as `vietnam_qr_pay-0.1.1.gem`.

## [0.1.0] - 2026-05-02

### Added

- Initial Ruby release of `VietnamQrPay`.
- VietQR payload parsing and generation.
- VNPayQR payload parsing and generation.
- Support for decoding related EMVCo-style provider payloads while preserving unknown provider data.
- Bank and bank app catalogs ported from the upstream JavaScript reference.
- Test coverage based on the upstream reference fixtures and expected payloads.
- RubyGems packaging metadata, release docs, and repository build/test tasks.
