# Changelog

## [0.2.0] - 2025-12-31

### Added
- **Suite Expansion**: Added 4 new "Omakase" benchmark suites:
  - `ViewHeft`: ActionView ERB rendering performance.
  - `ImageHeft`: ActiveStorage/Libvips image resizing.
  - `CacheHeft`: In-memory key/value throughput (SolidCache simulation).
  - `SearchHeft`: ActiveRecord text search queries.
- **Reporting**: Added `--json` flag for CI/CD compatible output.
- **Scoring**: Re-calibrated scoring weights:
  - Active Record: 40%
  - Job Processing: 20%
  - View Rendering: 20%
  - Image Processing: 10%
  - Cache Operations: 10%

### Changed
- **Dependencies**: Added `actionview`, `activestorage`, `image_processing` as runtime dependencies.
- **Calibration**: Adjusted weights to better reflect "Heft" on modern applications.

## [0.1.0] - 2025-12-29
- Initial Release ("Rails Awareness" update).
- CLI auto-detects Rails environment.
