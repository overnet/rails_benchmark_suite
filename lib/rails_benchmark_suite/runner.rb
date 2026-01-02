# frozen_string_literal: true

require "benchmark/ips"
require "get_process_mem"

module RailsBenchmarkSuite
  class Runner
    def initialize(suites, json: false)
      @suites = suites
      @json_output = json
    end

    def register(name, &block)
      @suites << { name: name, block: block }
    end

    SETUP_MUTEX = Mutex.new

    def run
      # Hardened Isolation: Shared Cache URI for multi-threading (v0.2.7)
      ActiveRecord::Base.establish_connection(
        adapter: "sqlite3",
        database: "file:heft_db?mode=memory&cache=shared",
        pool: 16,
        timeout: 10000
      )

      # The 'Busy Timeout' Hammer - force it directly on the raw connection
      ActiveRecord::Base.connection.raw_connection.busy_timeout = 10000
      
      # Setup Schema once safely with Mutex
      SETUP_MUTEX.synchronize do
        # Verify if schema already loaded by checking for a table
        unless ActiveRecord::Base.connection.table_exists?(:users)
          RailsBenchmarkSuite::Schema.load
        end
      end

      # High-Performance Pragmas
      ActiveRecord::Base.connection.raw_connection.execute("PRAGMA synchronous = OFF")
      ActiveRecord::Base.connection.raw_connection.execute("PRAGMA mmap_size = 268435456") # 256MB - reduce disk I/O

      puts "Running RailsBenchmarkSuite Benchmarks..." unless @json_output
      puts system_report unless @json_output
      puts "\n" unless @json_output

      results = {}

      @suites.each do |suite|
        puts "== Running Suite: #{suite[:name]} ==" unless @json_output
        
        # Capture memory before
        mem_before = GetProcessMem.new.mb

        # Run benchmark
        report = Benchmark.ips do |x|
          x.config(:time => 5, :warmup => 2)
          
          # Single Threaded
          x.report("#{suite[:name]} (1 thread)") do
            with_retries { suite[:block].call }
          end

          # Multi Threaded (4 threads)
          x.report("#{suite[:name]} (4 threads)") do
            threads = 4.times.map do
              Thread.new do
                # Ensure each thread gets a dedicated connection
                ActiveRecord::Base.connection_pool.with_connection do
                  with_retries { suite[:block].call }
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
        
        puts "Memory Footprint: #{mem_after.round(2)} MB (+#{(mem_after - mem_before).round(2)} MB)" unless @json_output
        puts "\n" unless @json_output
      end
      
      print_summary(results)
      results
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

    def system_report
      info = RailsBenchmarkSuite::Reporter.system_info
      yjit_status = if defined?(RubyVM::YJIT) && RubyVM::YJIT.enabled?
        "Enabled"
      else
        "Disabled (Requires Ruby with YJIT support for best results)"
      end
      "System: Ruby #{info[:ruby_version]} (#{info[:platform]}), #{info[:processors]} Cores. YJIT: #{yjit_status}. Libvips: #{info[:libvips]}"
    end

    def print_summary(results)
      if @json_output
        print_json(results)
        return
      end

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

    def print_json(results)
      require "json"
      
      out = {
        system: RailsBenchmarkSuite::Reporter.system_info,
        total_score: 0,
        suites: []
      }
      
      total_score = 0
      
      results.each do |name, data|
        weight = data[:weight] || 1.0
        
        # Parse reports
        ips_1t = data[:report].entries.find { |e| e.label.include?("(1 thread)") }&.ips || 0
        ips_4t = data[:report].entries.find { |e| e.label.include?("(4 threads)") }&.ips || 0
        
        weighted_score = ips_4t * weight
        total_score += weighted_score
        
        out[:suites] << {
          name: name,
          weight: weight,
          ips_1t: ips_1t,
          ips_4t: ips_4t,
          scaling: ips_1t > 0 ? (ips_4t / ips_1t) : 0,
          memory_delta_mb: data[:memory_delta_mb],
          score: weighted_score
        }
      end
      
      out[:total_score] = total_score.round(0)
      puts out.to_json
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
