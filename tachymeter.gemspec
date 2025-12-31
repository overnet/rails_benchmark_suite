# MIT License
# Copyright (c) 2024 RailsBenchmarkSuite Contributors

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

  spec.files         = Dir["lib/**/*", "bin/*", "README.md", "LICENSE"]
  spec.bindir        = "bin"
  spec.executables   = ["rails_benchmark_suite"]
  spec.require_paths = ["lib"]

  spec.add_dependency "benchmark-ips"
  spec.add_dependency "activerecord"
  spec.add_dependency "sqlite3"
  spec.add_dependency "concurrent-ruby"
  spec.add_dependency "get_process_mem"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
end
