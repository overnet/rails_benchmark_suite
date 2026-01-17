#!/usr/bin/env ruby
# frozen_string_literal: true

# Boot Structure Analysis - Standalone Profiler Script
# Executed as subprocess to measure cold boot times per app/ directory
# Outputs JSON to STDOUT

require "json"
require "benchmark"

results = []

begin
  # Boot Phase: Minimal Rails setup
  require "bundler/setup"
  
  # Check if we're in a Rails app
  env_file = File.join(Dir.pwd, "config", "environment.rb")
  unless File.exist?(env_file)
    # Not in a Rails app - output empty results
    puts "[]"
    exit 0
  end

  # Load Rails config without eager loading
  ENV["RAILS_ENV"] ||= "development"
  require File.join(Dir.pwd, "config", "application")
  
  # Profiling Phase: Measure each app/ subdirectory
  target_dirs = Dir.glob("app/*").select { |f| File.directory?(f) }

  target_dirs.each do |dir|
    files = Dir.glob("#{dir}/**/*.rb")
    next if files.empty?

    time_ms = Benchmark.realtime do
      files.each do |file|
        begin
          require file
        rescue LoadError, NameError, StandardError
          # Silently skip files with missing dependencies
        end
      end
    end * 1000 # Convert to milliseconds

    results << {
      path: dir,
      time_ms: time_ms.round(2),
      file_count: files.size
    }
  end

rescue => e
  # If anything fails, return error info for debugging
  results = [{ error: e.message, backtrace: e.backtrace&.first(3) }]
end

# Output JSON to STDOUT
puts results.to_json
