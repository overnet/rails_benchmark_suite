# frozen_string_literal: true

require "benchmark/ips"
require "get_process_mem"

module RailsBenchmarkSuite
  class WorkloadRunner
    # Base weights for each workload
    BASE_WEIGHTS = {
      "Active Record Heft" => 0.4,
      "View Heft" => 0.2,
      "Solid Queue Heft" => 0.2,
      "Cache Heft" => 0.1,
      "Image Heft" => 0.1
    }.freeze

    def initialize(workloads, show_progress: true)
      @workloads = workloads
      @show_progress = show_progress
    end

    def execute
      # Run all workloads and collect results
      results = @workloads.map.with_index do |w, index|
        if @show_progress
          Formatter.render_progress(index + 1, @workloads.size, w[:name], "Running")
        end
        
        result = run_single_workload(w)
        
        if @show_progress
          Formatter.render_progress(index + 1, @workloads.size, w[:name], "Done ✓")
        end
        
        result
      end
      
      # Calculate normalized weights
      weight_pool = results.sum { |r| BASE_WEIGHTS[r[:name]] || 0 }
      
      results.each do |r|
        base_weight = BASE_WEIGHTS[r[:name]] || 1.0
        r[:adjusted_weight] = base_weight / weight_pool
      end
      
      # Calculate total score
      total_score = results.sum do |r|
        entries = r[:report].entries
        entry_4t = entries.find { |e| e.label.include?("(4 threads)") }
        ips_4t = entry_4t ? entry_4t.ips : 0
        ips_4t * r[:adjusted_weight]
      end
      
      # Determine tier
      tier = if total_score < 50
        "Entry/Dev"
      elsif total_score < 200
        "Production-Ready"
      else
        "High-Performance"
      end
      
      # Return complete payload
      {
        results: results,
        total_score: total_score,
        tier: tier
      }
    end

    private

    def run_single_workload(workload)
      mem_before = GetProcessMem.new.mb

      # Run benchmark
      report = Benchmark.ips do |x|
        x.config(:time => 5, :warmup => 2)
        
        # Single Threaded
        x.report("#{workload[:name]} (1 thread)") do
          with_retries { workload[:block].call }
        end

        # Multi Threaded (4 threads)
        x.report("#{workload[:name]} (4 threads)") do
          threads = 4.times.map do
            Thread.new do
              ActiveRecord::Base.connection_pool.with_connection do
                with_retries { workload[:block].call }
              end
            end
          end
          threads.each(&:join)
        end

        x.compare!
      end

      mem_after = GetProcessMem.new.mb
      
      {
        name: workload[:name],
        report: report,
        memory_delta_mb: mem_after - mem_before
      }
    end

    def with_retries
      yield
    rescue ActiveRecord::StatementInvalid => e
      if e.message =~ /locked/i
        ActiveRecord::Base.connection.reset!
        sleep(rand(0.01..0.05))
        retry
      else
        raise e
      end
    end
  end
end
