# frozen_string_literal: true

require "concurrent"
require "rails_benchmark_suite/version"
require "rails_benchmark_suite/reporter"
require "rails_benchmark_suite/database_manager"
require "rails_benchmark_suite/workload_runner"
require "rails_benchmark_suite/formatter"
require "rails_benchmark_suite/runner"
require "rails_benchmark_suite/db_setup"
require "rails_benchmark_suite/schema"
require "rails_benchmark_suite/models/user"
require "rails_benchmark_suite/models/post"
require "rails_benchmark_suite/models/simulated_job"

module RailsBenchmarkSuite
  @workloads = []

  def self.register_workload(name, weight: 1.0, &block)
    @workloads << { name: name, weight: weight, block: block }
  end

  def self.run(options = {})
    # Load workloads
    Dir[File.join(__dir__, "rails_benchmark_suite", "workloads", "*.rb")].each { |f| require f }
    
    options[:json] ||= false
    Runner.new(@workloads, options).run
  end
end
