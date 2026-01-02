# frozen_string_literal: true

require_relative "lib/rails_benchmark_suite/version"

Gem::Specification.new do |spec|
  spec.name          = "rails_benchmark_suite"
  spec.version       = RailsBenchmarkSuite::VERSION
  spec.authors       = ["RailsBenchmarkSuite Contributors"]
  spec.email         = ["team@rails.org"]

  spec.summary       = "Rails-style functionality & performance benchmark tool"
  spec.description   = "Measures the 'Heft' (processing power) of a machine using realistic Rails workloads."
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

  spec.add_development_dependency "bundler", "~> 2.5"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "~> 5.0"

  spec.required_ruby_version = ">= 3.4.0"
end
