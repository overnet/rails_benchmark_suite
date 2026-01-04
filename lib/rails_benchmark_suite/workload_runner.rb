# frozen_string_literal: true

require "benchmark/ips"
require "get_process_mem"
require "tty-spinner"

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

    def initialize(workloads, options: {}, show_progress: true)
      @workloads = workloads
      @options = options
      @threads = options[:threads] || 4
      @profile_mode = options[:profile] || false
      @show_progress = show_progress
    end

    def execute
      if @profile_mode && @show_progress
        puts "\nRunning Scaling Diagnostic (Profile Mode)..."
      elsif @show_progress
        puts "\n⏳ Running Benchmarks..."
      end

      # Initializing MultiSpinner if progress is enabled
      multi_spinner = TTY::Spinner::Multi.new("[:spinner] Running Workloads", format: :dots) if @show_progress

      # Run all workloads and collect results
      results = @workloads.map do |w|
        spinner = nil
        if @show_progress
          spinner = multi_spinner.register("[:spinner] #{w[:name]}", format: :dots)
          spinner.auto_spin
        end
        
        result = run_single_workload(w, spinner)
        
        if @show_progress && spinner
          ips_1t = result[:report].entries.find { |e| e.label.include?("(1 thread)") }&.ips || 0
          ips_mt = result[:report].entries.find { |e| e.label.include?("(#{@threads} threads)") }&.ips || 0
          
          # Dynamic Success Message without duplicate name
          success_msg = " ... #{Reporter.humanize(ips_1t)} IPS (1T) | #{Reporter.humanize(ips_mt)} IPS (#{@threads}T)"
          spinner.success(success_msg)
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
        entry_mt = entries.find { |e| e.label.include?("(#{@threads} threads)") }
        ips_mt = entry_mt ? entry_mt.ips : 0
        ips_mt * r[:adjusted_weight]
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
        tier: tier,
        threads: @threads,
        profile_mode: @profile_mode
      }
    end

    private

    def run_single_workload(workload, spinner)
      mem_before = GetProcessMem.new.mb

      # Run benchmark
      report = Benchmark.ips do |x|
        # Silence output to allow spinner to own the UI
        x.config(:time => 5, :warmup => 2, :quiet => true)
        
        # Single Threaded
        x.report("#{workload[:name]} (1 thread)") do
          with_retries { workload[:block].call }
        end

        # Multi Threaded
        x.report("#{workload[:name]} (#{@threads} threads)") do
          threads = @threads.times.map do
            Thread.new do
              ActiveRecord::Base.connection_pool.with_connection do
                with_retries { workload[:block].call }
              end
            end
          end
          threads.each(&:join)
        end

        # x.compare! removed to prevent STDOUT pollution
      end

      mem_after = GetProcessMem.new.mb
      
      # Calculate Scaling Efficiency if in profile mode
      # Efficiency = (Multi Score / (Single Score * Threads)) * 100
      entries = report.entries
      entry_1t = entries.find { |e| e.label.include?("(1 thread)") }
      entry_mt = entries.find { |e| e.label.include?("(#{@threads} threads)") }
      
      efficiency = 0.0
      if entry_1t && entry_mt && entry_1t.ips > 0
        single_score = entry_1t.ips
        multi_score = entry_mt.ips
        efficiency = (multi_score / (single_score * @threads)) * 100
      end

      {
        name: workload[:name],
        report: report,
        memory_delta_mb: mem_after - mem_before,
        efficiency: efficiency
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
