# Rails Benchmark Suite

A standardized performance suite designed to measure the "Heft" of a machine using realistic, high-throughput Rails 8+ workloads.

Unlike synthetic CPU benchmarks, **Rails Benchmark Suite** simulates Active Record object allocation, SQL query complexity, ActionView rendering, and background job throughput.

## 📊 The "Heft" Score

The Heft Score is a weighted metric representing a machine's ability to handle Rails tasks. 
- **Baseline:** A score of **100** is calibrated to represent an **AWS c6g.large** (ARM) instance.
- **Objective:** To provide a simple, comparable number for evaluating different computing platforms (Cloud VMs, bare-metal, or local dev rigs).

### Baseline Comparisons
| Score | Classification | Comparable Hardware |
| :--- | :--- | :--- |
| < 40 | 🐢 Sluggish | Older Intel Macs, Entry-level VPS |
| 60 | 🚙 Capable | Standard Cloud VM (c5.large/standard) |
| **100** | **🏎️ Baseline** | **AWS c6g.large (2 vCPU ARM)** |
| 150+ | 🚀 High Performance | Apple M-series Pro/Max, Ryzen 5000+ |
| 300+ | ⚡ Blazing | Server-grade Metal, M3 Ultra |

## 🛠 Technical Philosophy

Rails Benchmark Suite prioritizes **Benchmarking** (via `benchmark-ips`) over **Profiling**.

* **Benchmarking:** Focuses on macro-throughput—"How many iterations can the hardware handle?" This provides the final Heft Score.
* **Why no Profiling?** Profiling tools (like `StackProf` or `Vernier`) introduce instrumentation overhead that skews hardware metrics. We aim for "Conceptual Compression"—one clear number to inform infrastructure decisions.

## 🚀 Installation & Usage

### Prerequisites
* **Ruby:** 3.4.1+ (Recommended for latest YJIT/Prism performance)
* **Database:** SQLite3

### Standalone Usage
If you want to test hardware performance without an existing application:

```bash
git clone https://github.com/overnet/rails_benchmark_suite.git
cd rails_benchmark_suite
bundle install
bin/rails_benchmark_suite
```

### Use within a Rails Application
Rails Benchmark Suite is "Rails-aware." Adding it to your app allows you to benchmark your specific configuration and custom suites.

Add to your Gemfile:

```ruby
gem "rails_benchmark_suite", group: :development
```

Run via bundle:

```bash
bundle exec rails_benchmark_suite
```

> **Note:** Use `--skip-rails` to ignore the host application and run in isolated mode.

## 🏗 Architecture
* **Engine:** Built on `benchmark-ips`.
* **Database:** Uses In-Memory SQLite with `cache=shared` for multi-threaded accuracy.
* **Isolation:** Uses transactional rollbacks (`ActiveRecord::Rollback`) to ensure test isolation without the overhead of row deletion.
* **Threading:** Supports 1-thread and 4-thread scaling tests to measure vertical efficiency.
* **Modern Stack:** Optimized for Rails 8+ defaults, including Solid Queue simulation and YJIT detection.

## 📜 Credits
This project is a functional implementation of the performance benchmark vision discussed in the Rails community.

* **Vision:** Inspired by @dhh in [rails/rails#50451](https://github.com/rails/rails/issues/50451).
* **Initial Roadmap:** Based on suggestions by @JoeDupuis.
* **Implementation:** The Rails Community.

## 📄 License
The gem is available as open source under the terms of the MIT License.
