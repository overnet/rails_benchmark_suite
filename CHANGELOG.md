# Changelog
## [0.3.1] - 2025-01-04

### 🛠️ CLI & Configuration
- **Dynamic Threading**: Added `-t/--threads` flag to control concurrency (defaults to `Etc.nprocessors` for full hardware utilization)
- **Scaling Profiler**: Added `-p/--profile` flag to run "Scaling Efficiency" diagnostics (generates "Joe Curve" metrics)
- **Real Database Mode**: Added `-d/--db` flag to connect to local `config/database.yml` instead of in-memory SQLite
- **Help**: Integrated `OptionParser` with auto-generated help (`-h` / `--help`)

### 🎨 TTY Output Overhaul
- **Dashboard UI**: Completely replaced scrolling text log with a "Heads Up Display" dashboard
- **Spinners**: Added `tty-spinner` for live progress updates ("Running Active Record... Done")
- **Rich Tables**: Implemented `tty-table` for the final report with clean borders and auto-padding
- **Visual Insights**: Use `tty-box` for the final score and `pastel` for color-coded efficiency metrics
- **Silence**: Suppressed raw `benchmark-ips` output for a cleaner CLI experience

### 🧠 Core Improvements
- **Hardware Awareness**: RHI calculation now defaults to utilizing ALL available cores, making it a true measure of total system capability
- **Efficiency Metric**: Formatter now calculates and displays "Efficiency %" `(Multi_IPS / (Single_IPS * Threads)) * 100`
- **Dynamic Labels**: Output table adjusts labels (e.g., "8T IPS") based on actual thread count used

### 🧪 Technical
- Renamed "Scaling" to "Efficiency" in some internal contexts for clarity
- Added critical unit tests for CLI argument parsing and math logic
- Refactored `Runner` to propagate configuration options via dependency injection

## [0.3.0] - 2025-01-03

### Major Architectural Refactor (SRP)
- **Runner Split**: Dismantled the monolithic `Runner` class (260+ lines) into three specialized modules:
  - `DatabaseManager`: Handles ActiveRecord connection, schema loading, and SQLite PRAGMA optimizations
  - `WorkloadRunner`: Manages benchmark execution engine with BASE_WEIGHTS normalization and complete payload generation
  - `Formatter`: Centralized UI rendering, ANSI colors, insights engine, and output formatting
- **Runner Coordinator**: `Runner` is now a minimal 23-line coordinator delegating to the three modules

### Normalized RHI Math Engine
- **BASE_WEIGHTS**: Defined workload weights (Active Record: 0.4, View: 0.2, Solid Queue: 0.2, Cache: 0.1, Image: 0.1)
- **Dynamic Weight Redistribution**: When workloads are skipped (e.g., missing libvips), weights are normalized proportionally to maintain 100% scale
- **Formula**: `RHI Score = Σ (4T_IPS × Adjusted_Weight)` where adjusted weights always sum to 1.0

### Performance Insights Engine
- **Scaling Analysis**: Warns when multi-threading scaling < 0.8x, indicating SQLite lock contention or Ruby GIL saturation
- **YJIT Detection**: Displays hint to enable YJIT when disabled (typical 15-25% boost)
- **Memory Monitoring**: Alerts when workload memory growth exceeds 20MB, suggesting heavy object allocation
- **Hardware Tiering**: Provides comparison labels (Entry/Dev < 50, Production-Ready 50-200, High-Performance > 200)

### UI/UX Enhancements
- **Box Alignment**: Fixed header and final score boxes with proper text length calculation (60-char width)
- **Table Spacing**: Added separator line between progress logs and results table for better readability
- **Insights Display**: Integrated insights below summary table with emoji indicators (💡, 📊)
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
