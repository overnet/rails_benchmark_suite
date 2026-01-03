# frozen_string_literal: true

module RailsBenchmarkSuite
  class Runner
    def initialize(workloads, json: false)
      @workloads = workloads
      @json_output = json
    end

    def run
      # Setup database
      db = DatabaseManager.new
      db.setup

      # Display header (unless JSON mode)
      Formatter.header(Reporter.system_info) unless @json_output

      # Execute all workloads
      results = []
      @workloads.each_with_index do |workload, index|
        # Show progress
        Formatter.render_progress(index + 1, @workloads.size, workload[:name], "Running") unless @json_output
        
        # Execute workload
        runner = WorkloadRunner.new(workload)
        data = runner.execute
        results << data
        
        # Mark complete
        Formatter.render_progress(index + 1, @workloads.size, workload[:name], "Done ✓") unless @json_output
      end

      # Render output
      if @json_output
        Formatter.as_json(results)
      else
        Formatter.render_summary_table(results)
      end

      results
    end

    private

    def system_report
      info = RailsBenchmarkSuite::Reporter.system_info
      yjit_status = if defined?(RubyVM::YJIT) && RubyVM::YJIT.enabled?
        "Enabled"
      else
        "Disabled (Requires Ruby with YJIT support for best results)"
      end
      "System: Ruby #{info[:ruby_version]} (#{info[:platform]}), #{info[:processors]} Cores. YJIT: #{yjit_status}. Libvips: #{info[:libvips]}"
    end
  end
end
