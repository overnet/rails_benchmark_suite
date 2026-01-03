# frozen_string_literal: true

module RailsBenchmarkSuite
  class Runner
    def initialize(workloads, json: false)
      @workloads = workloads
      @json_output = json
    end

    def run
      DatabaseManager.new.setup
      Formatter.header(Reporter.system_info) unless @json_output
      
      # Delegate ALL math and execution to the WorkloadRunner
      payload = WorkloadRunner.new(@workloads, show_progress: !@json_output).execute
      
      if @json_output
        Formatter.as_json(payload)
      else
        Formatter.summary_with_insights(payload)
      end
    end
  end
end
