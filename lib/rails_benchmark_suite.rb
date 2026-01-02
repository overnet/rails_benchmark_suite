# frozen_string_literal: true

require "concurrent"
require "rails_benchmark_suite/version"
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

  def self.run(json: false)
    # Enforce database isolation: Always use in-memory SQLite, ignoring host app DB
    ActiveRecord::Base.establish_connection(
      adapter: "sqlite3",
      database: "file:rails_benchmark_suite_mem?mode=memory&cache=shared",
      pool: 20,
      timeout: 10000
    )

    # SQLite Performance Tuning for multi-threaded benchmarks
    db = ActiveRecord::Base.connection.raw_connection
    db.execute("PRAGMA journal_mode = WAL")      # Write-Ahead Logging
    db.execute("PRAGMA synchronous = NORMAL")   # Faster writes
    db.execute("PRAGMA busy_timeout = 5000")    # Wait for lock instead of crashing

    # Load Schema
    RailsBenchmarkSuite::Schema.load
    
    # Load suites
    Dir[File.join(__dir__, "rails_benchmark_suite", "suites", "*.rb")].each { |f| require f }
    
    runner = Runner.new(@suites, json: json)
    runner.run
  end
end
