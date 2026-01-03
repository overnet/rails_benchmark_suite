# Changelog

## [0.3.0] - 2026-01-03

### 🏗️ Architecture
- **Major Refactor**: Split monolithic Runner (260+ lines) into three focused modules following SRP:
  - `DatabaseManager`: Handles all ActiveRecord connection, schema loading, and PRAGMA optimizations
  - `WorkloadRunner`: Executes benchmarks with threading and retry logic
  - `Formatter`: Manages all UI rendering, ANSI colors, and output formatting
- **Runner Transformation**: Reduced to ~50 lines as a thin coordinator that delegates to specialized modules
- **Breaking**: Renamed "Suite" → "Workload" throughout codebase for clearer terminology
- Reorganized directory structure: `lib/rails_benchmark_suite/suites/` → `lib/rails_benchmark_suite/workloads/`
- Updated API: `register_suite` → `register_workload`

### 🚀 Features & UX
- **Rails Heft Index (RHI)**: Introduced official scoring terminology and branding
- **Hardware Tier Classification**: Automatic tier assignment (Entry/Dev, Production-Ready, High-Performance)
- **Enterprise Box UI**: Professional report design with UTF-8 box drawing characters (┌─┐ and ╔═╗)
- **Colorized Scaling Metrics**: Red/Yellow/Green ANSI color indicators for multi-threading efficiency  
  - Red: < 0.3x (Poor scaling)
  - Yellow: 0.3x-0.6x (Moderate scaling)
  - Green: > 0.6x (Good scaling)
- **Progress Indicators**: Real-time `[1/5] Running... Done ✓` feedback for each workload
- **Enhanced Number Formatting**: Smart k/M suffixes for readability (e.g., "15.3k", "1.2M")
- **YJIT Hints**: Helpful reminder `(run with RUBY_OPT="--yjit" for max perf)` when YJIT is disabled
- Silent migrations: Added `ActiveRecord::Migration.verbose = false` to reduce noise
- Cross-platform install instructions for libvips (macOS and Linux)

### 🐛 Fixes
- Fixed `.gitignore` to properly track `gemspec` file for gem distribution
- **JSON Guard**: Ensures clean JSON output without any UI noise when `--json` flag is used
- Improved CLI output suppression in JSON mode

### 📖 Documentation
- **Calculation Formula**: Added "How It's Calculated" section with RHI formula: `Σ (4-Thread IPS × Weight)`
- **Workload Weights Table**: Documented weights (Active Record 40%, View 20%, Jobs 20%, Cache 10%, Image 10%)
- **Hardware Tiers**: Explained tier classification system
- Complete README rewrite with four execution methods:
  - Standard: `bundle exec rails_benchmark_suite`
  - High Performance: `RUBY_OPT="--yjit" bundle exec rails_benchmark_suite` 
  - JSON Export: `bundle exec rails_benchmark_suite --json > report.json`
  - Standalone: `bin/rails_benchmark_suite`
- Added comprehensive System Requirements section
- Updated all terminology from "Suite" to "Workload"

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
