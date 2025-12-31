# MIT License
# Copyright (c) 2024 RailsBenchmarkSuite Contributors

require "benchmark/ips"
require "get_process_mem"

module RailsBenchmarkSuite
  class Runner
    def initialize(suites)
      @suites = suites
    end

    def register(name, &block)
      @suites << { name: name, block: block }
    end

    def run
      puts "Running RailsBenchmarkSuite Benchmarks..."
      puts system_report
      puts "\n"

      results = {}

      @suites.each do |suite|
        puts "== Running Suite: #{suite[:name]} =="
        
        # Capture memory before
        mem_before = GetProcessMem.new.mb

        # Run benchmark
        report = Benchmark.ips do |x|
          x.config(:time => 5, :warmup => 2)
          
          # Single Threaded
          x.report("#{suite[:name]} (1 thread)") do
            suite[:block].call
          end

          # Multi Threaded (4 threads)
          x.report("#{suite[:name]} (4 threads)") do
            threads = 4.times.map do
              Thread.new do
                # Ensure each thread gets a dedicated connection
                ActiveRecord::Base.connection_pool.with_connection do
                  suite[:block].call
                end
              end
            end
            threads.each(&:join)
          end

          x.compare!
        end

        # Capture memory after
        mem_after = GetProcessMem.new.mb
        
        results[suite[:name]] = {
          report: report,
          memory_delta_mb: mem_after - mem_before,
          weight: suite[:weight]
        }
        
        puts "Memory Footprint: #{mem_after.round(2)} MB (+#{(mem_after - mem_before).round(2)} MB)"
        puts "\n"
      end
      
      print_summary(results)
      results
    end

    private

    def system_report
      info = RailsBenchmarkSuite::Reporter.system_info
      "System: Ruby #{info[:ruby_version]} (#{info[:platform]}), #{info[:processors]} Cores. YJIT: #{info[:yjit]}. Libvips: #{info[:libvips]}"
    end

    def print_summary(results)
      puts "\n"
      puts "=========================================================================================="
      puts "| %-25s | %-25s | %-12s | %-15s |" % ["Suite", "IPS (1t / 4t)", "Scaling", "Mem Delta"]
      puts "=========================================================================================="
      
      total_score = 0
      
      results.each do |name, data|
        report = data[:report]
        entries = report.entries
        
        entry_1t = entries.find { |e| e.label.include?("(1 thread)") }
        entry_4t = entries.find { |e| e.label.include?("(4 threads)") }
        
        ips_1t = entry_1t ? entry_1t.ips : 0
        ips_4t = entry_4t ? entry_4t.ips : 0
        
        scaling = ips_1t > 0 ? (ips_4t / ips_1t) : 0
        mem = data[:memory_delta_mb]
        
        # Heft Score: Weighted Sum of 4t IPS
        weight = data[:weight] || 1.0
        weighted_score = ips_4t * weight
        total_score += weighted_score
        
        puts "| %-25s | %-25s | x%-11.2f | +%-14.2fMB |" % [
          name + " (w: #{weight})", 
          "#{humanize(ips_1t)} / #{humanize(ips_4t)}",
          scaling, 
          mem
        ]
      end
      puts "=========================================================================================="
      puts "\n"
      puts "  >>> FINAL HEFT SCORE: #{total_score.round(0)} <<<"
      puts "\n"
    end

    def humanize(ips)
      return "0" if ips.nil?
      if ips > 1000
        "%.1fk" % (ips / 1000.0)
      else
        "%.1f" % ips
      end
    end
  end
end
