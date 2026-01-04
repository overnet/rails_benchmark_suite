# frozen_string_literal: true

require_relative "lib/rails_benchmark_suite/version"

Gem::Specification.new do |spec|
  spec.name          = "rails_benchmark_suite"
  spec.version       = RailsBenchmarkSuite::VERSION
  spec.authors       = ["RailsBenchmarkSuite Contributors"]
  spec.email         = ["team@rails.org"]

  spec.summary       = "Rails Heft Index (RHI) - Hardware benchmarking using realistic workloads"
  spec.description   = "Measures the Rails Heft Index (RHI), a weighted performance score based on realistic Rails 8+ workloads across Active Record, caching, views, jobs, and image processing."
  spec.homepage      = "https://github.com/overnet/rails_benchmark_suite"
  spec.license       = "MIT"

  spec.metadata["source_code_uri"] = "https://github.com/overnet/rails_benchmark_suite"
  spec.metadata["bug_tracker_uri"] = "https://github.com/overnet/rails_benchmark_suite/issues"
  spec.metadata["changelog_uri"] = "https://github.com/overnet/rails_benchmark_suite/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "bin"
  spec.executables   = ["rails_benchmark_suite"]
  spec.require_paths = ["lib"]

  spec.add_dependency "benchmark-ips", "~> 2.14"
  spec.add_dependency "activerecord", "~> 8.1"
  spec.add_dependency "actionview", "~> 8.1"
  spec.add_dependency "activestorage", "~> 8.1"
  spec.add_dependency "image_processing", "~> 1.14"
  spec.add_dependency "sqlite3", "~> 2.8"
  spec.add_dependency "concurrent-ruby", "~> 1.3"
  spec.add_dependency "get_process_mem", "~> 1.0"
  spec.add_dependency "tty-spinner", "~> 0.9"
  spec.add_dependency "tty-table", "~> 0.12"
  spec.add_dependency "tty-box", "~> 0.7"
  spec.add_dependency "pastel", "~> 0.8"

  spec.add_development_dependency "bundler", "~> 2.5"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "ostruct", "~> 0.6"

  spec.required_ruby_version = ">= 3.4.0"
end
