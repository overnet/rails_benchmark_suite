# frozen_string_literal: true

require "benchmark/ips"
require "get_process_mem"

module RailsBenchmarkSuite
  class WorkloadRunner
    def initialize(workload)
      @workload = workload
    end

    def execute
      mem_before = GetProcessMem.new.mb

      # Run benchmark
      report = Benchmark.ips do |x|
        x.config(:time => 5, :warmup => 2)
        
        # Single Threaded
        x.report("#{@workload[:name]} (1 thread)") do
          with_retries { @workload[:block].call }
        end

        # Multi Threaded (4 threads)
        x.report("#{@workload[:name]} (4 threads)") do
          threads = 4.times.map do
            Thread.new do
              # Ensure each thread gets a dedicated connection
              ActiveRecord::Base.connection_pool.with_connection do
                with_retries { @workload[:block].call }
              end
            end
          end
          threads.each(&:join)
        end

        x.compare!
      end

      mem_after = GetProcessMem.new.mb
      
      {
        name: @workload[:name],
        report: report,
        memory_delta_mb: mem_after - mem_before,
        weight: @workload[:weight]
      }
    end

    private

    def with_retries
      yield
    rescue ActiveRecord::StatementInvalid => e
      if e.message =~ /locked/i
        # Specifically drop the lock for THIS connection only
        ActiveRecord::Base.connection.reset!
        sleep(rand(0.01..0.05))
        retry
      else
        raise e
      end
    end
  end
end
