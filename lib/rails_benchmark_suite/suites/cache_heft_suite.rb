# MIT License
# Copyright (c) 2024 RailsBenchmarkSuite Contributors

require "active_support/cache"
require "securerandom"

# Benchmark Suite
RailsBenchmarkSuite.register_suite("Cache Heft", weight: 0.1) do
  # Simulate SolidCache using MemoryStore
  @cache ||= ActiveSupport::Cache::MemoryStore.new
  
  # Workload: Measure serialization and storage throughput
  key_prefix = "cache_test_#{SecureRandom.hex(4)}"
  
  # 1. Bulk Write
  100.times do |i|
    @cache.write("#{key_prefix}/#{i}", { data: "Precious Data " * 20, index: i })
  end
  
  # 2. Bulk Read
  100.times do |i|
    val = @cache.read("#{key_prefix}/#{i}")
    next if val.nil?
  end
  
  # 3. Clean up
  @cache.clear
end
