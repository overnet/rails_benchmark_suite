# frozen_string_literal: true

require_relative "lib/rails_benchmark_suite/version"

Gem::Specification.new do |spec|
  spec.name          = "rails_benchmark_suite"
  spec.version       = RailsBenchmarkSuite::VERSION
  spec.authors       = ["RailsBenchmarkSuite Contributors"]
  spec.email         = ["team@rails.org"]

  spec.summary       = "Rails-style functionality & performance benchmark tool"
  spec.description   = "Measures the 'Heft' (processing power) of a machine using realistic Rails workloads."
  spec.homepage      = "https://github.com/rails/rails_benchmark_suite"
  spec.license       = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/rails/rails_benchmark_suite"
  spec.metadata["changelog_uri"] = "https://github.com/rails/rails_benchmark_suite/blob/main/CHANGELOG.md"

  spec.files         = Dir["lib/**/*", "bin/*", "README.md", "LICENSE.txt"]
  spec.bindir        = "bin"
  spec.executables   = ["rails_benchmark_suite"]
  spec.require_paths = ["lib"]

  spec.add_dependency "benchmark-ips"
  spec.add_dependency "activerecord"
  spec.add_dependency "actionview"
  spec.add_dependency "activestorage"
  spec.add_dependency "image_processing"
  spec.add_dependency "sqlite3"
  spec.add_dependency "concurrent-ruby"
  spec.add_dependency "get_process_mem"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"

  spec.required_ruby_version = ">= 3.4.0"
end
