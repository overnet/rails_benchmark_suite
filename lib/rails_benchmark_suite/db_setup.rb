# MIT License
# Copyright (c) 2024 RailsBenchmarkSuite Contributors

require "active_record"
require "sqlite3"

# Silence ActiveRecord logs during benchmarks to avoid IO bottlenecks
ActiveRecord::Base.logger = nil

# Setup In-Memory SQLite globally for all suites
# storage_config = ActiveRecord::DatabaseConfigurations::HashConfig.new("test", "sqlite3", { adapter: "sqlite3", database: ":memory:" })
# Use shared cache to allow threads to see the same in-memory database
ActiveRecord::Base.establish_connection(
  adapter: "sqlite3", 
  database: "file:rails_benchmark_suite_mem?mode=memory&cache=shared", 
  pool: 20,
  timeout: 10000
)
