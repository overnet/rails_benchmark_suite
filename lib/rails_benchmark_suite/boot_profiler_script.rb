#!/usr/bin/env ruby
# frozen_string_literal: true

# Boot Structure Analysis - Standalone Profiler Script
# Executed as subprocess to measure cold boot times per app/ directory
# Outputs JSON to STDOUT
# 
# IMPORTANT: Uses stdout silencing to handle noisy Rails boots that may
# output deprecation warnings or logs during require statements.

require "json"
require "benchmark"

# Output Silencer - swallows all puts/print from Rails boot
def silence_stdout
  original_stdout = $stdout
  original_stderr = $stderr
  $stdout = File.open(File::NULL, "w")
  $stderr = File.open(File::NULL, "w")
  yield
ensure
  $stdout = original_stdout
  $stderr = original_stderr
end

results = []

begin
  # Boot Phase: Minimal Rails setup (silenced to avoid noisy output)
  silence_stdout do
    require "bundler/setup"
    
    # Check if we're in a Rails app
    env_file = File.join(Dir.pwd, "config", "environment.rb")
    unless File.exist?(env_file)
      # Not in a Rails app - will output empty results after restore
      break
    end

    # Load Rails config without eager loading
    ENV["RAILS_ENV"] ||= "development"
    require File.join(Dir.pwd, "config", "application")
  end
  
  # Check if we're in a Rails app (outside silence block)
  env_file = File.join(Dir.pwd, "config", "environment.rb")
  unless File.exist?(env_file)
    puts "[]"
    exit 0
  end
  
  # Profiling Phase: Measure each app/ subdirectory
  target_dirs = Dir.glob("app/*").select { |f| File.directory?(f) }

  target_dirs.each do |dir|
    files = Dir.glob("#{dir}/**/*.rb")
    next if files.empty?

    time_ms = Benchmark.realtime do
      # Silence loading phase - models/controllers often trigger logs
      silence_stdout do
        files.each do |file|
          begin
            require file
          rescue LoadError, NameError, StandardError
            # Silently skip files with missing dependencies
          end
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

# Output JSON to STDOUT (only after restoring stdout)
puts results.to_json
