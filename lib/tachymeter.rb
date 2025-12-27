# MIT License
# Copyright (c) 2024 RailsBenchmarkSuite Contributors

require "concurrent"
require "rails_benchmark_suite/reporter"
require "concurrent"
require "rails_benchmark_suite/reporter"
require "rails_benchmark_suite/runner"
require "rails_benchmark_suite/db_setup"
require "rails_benchmark_suite/schema"
require "rails_benchmark_suite/models/user"
require "rails_benchmark_suite/models/post"
require "rails_benchmark_suite/models/simulated_job"

module RailsBenchmarkSuite
  @suites = []

  def self.register_suite(name, weight: 1.0, &block)
    @suites << { name: name, weight: weight, block: block }
  end

  def self.run
    # Load Schema
    RailsBenchmarkSuite::Schema.load
    
    # Load suites
    Dir[File.join(__dir__, "rails_benchmark_suite", "suites", "*.rb")].each { |f| require f }
    
    runner = Runner.new(@suites)
    runner.run
  end
end
