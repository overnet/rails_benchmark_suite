# RailsBenchmarkSuite

> **RailsBenchmarkSuite** /tak-im-i-ter/ (noun): An instrument for measuring speed; specifically, a benchmark tool for modern Rails applications.

RailsBenchmarkSuite is a **functionality & performance benchmark suite** designed to measure the "Heft" (processing power) of a machine using realistic, high-throughput Rails workloads. Unlike synthetic CPU benchmarks, RailsBenchmarkSuite simulates **Active Record object allocation, SQL query mix, and transaction latency**.

## 📊 The "Heft" Score

The **Heft Score** is a weighted metric representing your machine's ability to handle Rails tasks. A score of **100** is calibrated to represent a standard cloud compute baseline (roughly equivalent to an **AWS c6g.large** ARM instance).

### Baseline Comparison
| Score | Classification | Comparable Hardware |
| :--- | :--- | :--- |
| **< 40** | 🐢 Sluggish | Older Intel Macs, Entry-level VPS |
| **60** | 🚙 Capable | Standard Cloud VM (c5.large/standard), older M1 Air |
| **100** | 🏎️ **Baseline** | **AWS c6g.large (2 vCPU ARM)** |
| **150+** | 🚀 High Performance | Apple M1/M2/M3 Pro/Max, Ryzen 5000+ |
| **300+** | ⚡ Blazing | Server-grade Metal, M3 Ultra |

## 🚀 Installation & Usage

### Prerequisites
- Ruby 3.3+ (Recommended)
- SQLite3

### Run the Benchmark
Clone the repository and run the executable:

```bash
git clone https://github.com/rails/rails_benchmark_suite.git
cd rails_benchmark_suite
bundle install
bin/rails_benchmark_suite
```

### Using in a Rails Application
RailsBenchmarkSuite is "Rails-aware." If you run it inside a Rails project, it will automatically load your environment, allowing you to benchmark against your real database connection or models if you write custom suites.

1. Add to your `Gemfile`:
   ```ruby
   gem "rails_benchmark_suite", path: "path/to/rails_benchmark_suite", group: :development
   # Or once published:
   # gem "rails_benchmark_suite", group: :development
   ```

2. Run via bundle:
   ```bash
   bundle exec rails_benchmark_suite
   ```

   *Note: Use `--skip-rails` to ignore the host application and run isolated.*

### Sample Output
```text
== Running Suite: Active Record Heft ==
Active Record Heft (1 thread)   475.7 i/s
Active Record Heft (4 threads)  116.4 i/s

== Running Suite: Job Heft ==
Job Heft (1 thread)             34.7 i/s
Job Heft (4 threads)            14.1 i/s

>>> FINAL HEFT SCORE: 86 <<<
```

## 🛠 Architecture

RailsBenchmarkSuite is designed with Rails Core standards in mind:

- **Benchmark Engine**: Built on `benchmark-ips`.
- **Database**: Uses **In-Memory SQLite** with `cache=shared` mode to allow truthful multi-threaded benchmarking without disk I/O noise.
- **Rollback Strategy**: Uses `ActiveRecord::Base.transaction { ... raise Rollback }` to ensure infinite test isolation without the overhead of `DELETE` statements.
- **Thread Safety**: Explicit connection pooling (`with_connection`) ensures thread-safe execution across scaling tests.

## 🧪 Development

Run the test suite to verify internal logic:

```bash
rake test
```

## License
MIT.
