# Rails Benchmark Suite 🚀

**Standardized Hardware Benchmarking for Rails 8.1+**

A standardized performance suite designed to measure the "Heft" of a machine using realistic, high-throughput Rails 8+ workloads.

## 🛠 What is this?

Think of this as a **"Test Track" for Rails servers**. Unlike profilers that measure your specific application code, this gem runs a **fixed, standardized set of Rails operations** (Active Record object allocation, SQL query complexity, ActionView rendering, and background job throughput) to measure the raw performance of your server and Ruby configuration.

To ensure a level playing field, the gem boots an **isolated, in-memory SQLite environment**. It creates its own schema and records, meaning it **never touches your production data** and returns comparable results across any machine.

## 📊 The "Heft" Score

The Heft Score is a weighted metric representing a machine's ability to handle Rails tasks.
* **Baseline:** A score of **100** is calibrated to represent an **AWS c6g.large** (ARM) instance.
* **Objective:** To provide a simple, comparable number for evaluating different computing platforms (Cloud VMs, bare-metal, or local dev rigs).

### Baseline Comparisons

| Score | Classification | Comparable Hardware |
| :--- | :--- | :--- |
| **< 40** | 🐢 Sluggish | Older Intel Macs, Entry-level VPS |
| **60** | 🚙 Capable | Standard Cloud VM (c5.large/standard) |
| **100** | 🏎️ Baseline | AWS c6g.large (2 vCPU ARM) |
| **150+** | 🚀 High Performance | Apple M-series Pro/Max, Ryzen 5000+ |
| **300+** | ⚡ Blazing | Server-grade Metal, M3 Ultra |

---

## 🚀 Quick Start

Ensure you are in your Rails root directory and run:

```bash
ruby --yjit -S bundle exec rails_benchmark_suite
```

**Note:** `bundle exec` is mandatory for Rails environment stability and to prevent Minitest version conflicts.

---

## 🛠 Technical Philosophy

Rails Benchmark Suite prioritizes **Benchmarking** (via `benchmark-ips`) over **Profiling**.

* **Benchmarking:** Focuses on macro-throughput—"How many iterations can the hardware handle?" This provides the final Heft Score.
* **Why no Profiling?** Profiling tools (like `StackProf` or `Vernier`) introduce instrumentation overhead that skews hardware metrics. We aim for "Conceptual Compression"—one clear number to inform infrastructure decisions.

---

## 🚀 Installation & Usage

### Requirements
* **Ruby:** 3.3+ (Ruby with YJIT support highly recommended)
* **Rails:** 8.1+
* **Database:** SQLite3

## 📋 System Requirements

### Required
- **Ruby**: 3.3+ (3.4+ recommended for YJIT)
- **Rails**: 8.0+  
- **Database**: SQLite3

### Optional (for Image Heft workload)
- **macOS**: `brew install vips`
- **Linux (Ubuntu/Debian)**: `sudo apt install libvips-dev`

---

## 🚀 Usage

### Standard Execution
```bash
bundle exec rails_benchmark_suite
```
The easy way - run the benchmark with your current Ruby configuration.

### High Performance (Recommended)
```bash
RUBY_OPT="--yjit" bundle exec rails_benchmark_suite
```
Enable YJIT for maximum performance measurement accuracy. This is the recommended method for Rails 8+ benchmarking.

### JSON Export (Automation)
```bash
bundle exec rails_benchmark_suite --json > report.json
```
Perfect for CI/CD pipelines and programmatic analysis. Outputs clean JSON without any UI elements.

### Configuration Flags
- `-t` / `--threads N`: Set thread count manually (default: auto-detect cores)
- `-p` / `--profile`: Enable "Scaling Efficiency" profile mode (compares 1-thread vs N-threads)
- `-d` / `--db`: Connect to your local `config/database.yml` instead of default in-memory SQLite
- `--json`: Output results in JSON format
- `--skip-rails`: Run in isolated mode without loading Rails environment
- `--version`: Display gem version
- `-h` / `--help`: Show usage help

### Standalone Usage

If you want to test hardware performance without an existing application:

```bash
git clone https://github.com/overnet/rails_benchmark_suite.git
cd rails_benchmark_suite
bundle install
bin/rails_benchmark_suite
```

---

## 📐 How It's Calculated

The **Rails Heft Index (RHI)** measures your hardware's ability to handle Rails workloads using this formula:

```
RHI Score = Σ (4-Thread IPS × Weight)
```

### Workload Weights

| Workload | Weight | Rationale |
|----------|--------|-----------|  
| **Active Record** | 40% | Database operations are the core of most Rails apps |
| **View Rendering** | 20% | ERB/ActionView processing |
| **Solid Queue** | 20% | Background job throughput |
| **Cache Operations** | 10% | Memory store performance |
| **Image Processing** | 10% | Optional - requires libvips |

**Why 4-Thread IPS?** We use 4-thread performance to simulate production concurrency where multiple requests are handled simultaneously.

**Dynamic Weight Redistribution:** If a workload is skipped (e.g., Image Processing without libvips), its weight is redistributed proportionally among remaining workloads to maintain a 100% scale.

### Hardware Tiers

Your RHI score maps to these performance tiers:

- **< 50**: Entry/Dev - Suitable for local development
- **50-200**: Production-Ready - Handles moderate production traffic
- **> 200**: High-Performance - Optimized for high-traffic applications

---

## 🧪 The "Heft" Workloads

The gem measures performance across critical Rails subsystems using a dedicated, isolated schema:

* **Active Record Heft:** Standardized CRUD: Creation, indexing, and complex querying.
* **Cache Heft:** High-frequency read/writes to the Rails memory store.
* **Solid Queue Heft:** Background job enqueuing and database-backed polling stress.
* **View Heft:** Partial rendering overhead and ActionView throughput.
* **Image Heft:** Image processing performance (requires libvips).

---

## ⚠️ Troubleshooting

### YJIT Shows "Disabled"

If you see `YJIT: Disabled`, it means your Ruby was not compiled with YJIT support.

* **Fix (rbenv):** `RUBY_CONFIGURE_OPTS="--enable-yjit" rbenv install 3.4.1`
* **Fix (rvm):** `rvm install 3.4.1 --enable-yjit`

### SQLite Lock Errors

Version 0.2.9+ includes surgical connection resets and randomized backoffs to handle SQLite concurrency. If issues persist, ensure no other processes are accessing the benchmark database.

---

## 🏗 Architecture

* **Engine:** Built on `benchmark-ips`.
* **Database:** Uses In-Memory SQLite with `cache=shared` and a 50-connection pool for multi-threaded accuracy.
* **Isolation:** Uses transactional rollbacks and Mutex-wrapped schema creation.
* **Threading:** Supports 1-thread and 4-thread scaling tests.

---

## 📜 Credits

* **Vision:** Inspired by @dhh in [rails/rails#50451](https://github.com/rails/rails/issues/50451).
* **Initial Roadmap:** Based on suggestions by @JoeDupuis.
* **Implementation:** The Rails Community.

---

## 📄 License

The gem is available as open source under the terms of the MIT License.
