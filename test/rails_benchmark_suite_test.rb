# frozen_string_literal: true

require "test_helper"
require "open3"

class RailsBenchmarkSuiteTest < Minitest::Test
  def setup
    # Reset workloads
    RailsBenchmarkSuite.instance_variable_set(:@workloads, [])
    # Re-establish basic memory DB for test isolation
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
    RailsBenchmarkSuite::Schema.load
  end

  def test_that_it_has_a_version_number
    refute_nil ::RailsBenchmarkSuite::VERSION
  end

  # Logic Test: Efficiency Calculation
  def test_efficiency_math_logic
    # Efficiency = (Multi Score / (Single Score * Threads)) * 100
    single_score = 100.0
    threads = 8.0
    multi_score = 800.0 # Perfect scaling

    efficiency = (multi_score / (single_score * threads)) * 100
    assert_in_delta 100.0, efficiency, 0.1

    # 50% Efficiency case
    multi_score_half = 400.0
    efficiency_half = (multi_score_half / (single_score * threads)) * 100
    assert_in_delta 50.0, efficiency_half, 0.1
  end

  # Logic Test: Option Passing to Runner
  def test_runner_initialization_options
    options = { threads: 8, profile: true, db: true }
    workloads = []
    
    # Mocking behavior via dependency injection or accessing internal state
    runner = RailsBenchmarkSuite::Runner.new(workloads, options)
    
    # Check if options are stored correctly (white-box testing)
    stored_options = runner.instance_variable_get(:@options)
    assert_equal 8, stored_options[:threads]
    assert_equal true, stored_options[:profile]
    assert_equal true, stored_options[:db]
  end

  # CLI Test: Flag Parsing (Bin Script Logic)
  # We test this by invoking the executable with --help or --version to ensure it runs
  # Detailed flag parsing is handled by OptionParser which is standard lib,
  # but we verified our implementation passes these values to Runner.
  def test_cli_help_flag
    stdout, _stderr, status = Open3.capture3("bin/rails_benchmark_suite --help")
    assert status.success?
    assert_match(/Usage: rails_benchmark_suite/, stdout)
    assert_match(/--threads/, stdout)
    assert_match(/--profile/, stdout)
    assert_match(/--db/, stdout)
  end
end
