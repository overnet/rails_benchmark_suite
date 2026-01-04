# frozen_string_literal: true

module RailsBenchmarkSuite
  class Runner
    def initialize(workloads, options = {})
      @workloads = workloads
      @options = options
      @json_output = options[:json] || false
    end

    def run
      DatabaseManager.new.setup(use_local_db: @options[:db])
      Formatter.header(Reporter.system_info.merge(threads: @options[:threads])) unless @json_output
      
      # Delegate ALL math and execution to the WorkloadRunner
      payload = WorkloadRunner.new(
        @workloads, 
        options: @options,
        show_progress: !@json_output
      ).execute
      
      if @json_output
        Formatter.as_json(payload)
      else
        Formatter.summary_with_insights(payload)
      end
    end
  end
end
