require_relative "database_manager"
require_relative "workload_runner"
require_relative "reporter"
require_relative "schema"
require_relative "../dummy/app/models/benchmark_user"
require_relative "../dummy/app/models/benchmark_post"
require_relative "../dummy/app/models/benchmark_job"
require "open3"
require "json"

module RailsBenchmarkSuite
  class Runner
    # Registry for workloads
    @workloads = []

    def self.register_workload(name, weight: 1.0, &block)
      @workloads << { name: name, weight: weight, block: block }
    end

    def initialize(config)
      @config = config
    end

    def run
      # Load workloads dynamically if not already loaded (idempotent)
      if Runner.instance_variable_get(:@workloads).empty?
        Dir[File.join(__dir__, "workloads", "*.rb")].each { |f| require f }
      end

      # 1. Setup Database
      DatabaseManager.new.setup(use_local_db: @config.db)
      
      # 2. Display Header
      header_info = Reporter.system_info.merge(
        threads: @config.threads,
        db_mode: @config.db_mode
      )
      Reporter.header(header_info) unless @config.json
      
      # 3. Execute Workloads
      # Passing config values as options to WorkloadRunner for compatibility
      # Ideally we'd pass the config object but WorkloadRunner expects a hash currently
      # We will refactor WorkloadRunner to accept config later or wrap it here
      runner_options = {
        threads: @config.threads,
        profile: @config.profile
      }
      
      payload = WorkloadRunner.new(
        Runner.instance_variable_get(:@workloads), 
        options: runner_options,
        show_progress: !@config.json
      ).execute

      # 4. Boot Structure Analysis (run for all modes including JSON)
      payload[:boot_analysis] = run_boot_analysis
      
      # 5. Report Results
      if @config.json
        Reporter.as_json(payload)
      else
        Reporter.render(payload)
      end

      # 6. HTML Report Generation
      if @config.html
        require_relative "reporters/html_reporter"
        Reporters::HtmlReporter.new(payload).generate
      end
    end

    private

    def run_boot_analysis
      script_path = File.join(__dir__, "boot_profiler_script.rb")
      return nil unless File.exist?(script_path)

      begin
        stdout, status = Open3.capture2("bundle", "exec", "ruby", script_path)
        return nil unless status.success?

        results = JSON.parse(stdout, symbolize_names: true)
        return nil if results.empty? || results.first&.dig(:error)

        # Sort by load time descending (slowest first)
        results.sort_by { |r| -(r[:time_ms] || 0) }
      rescue JSON::ParserError, StandardError
        nil
      end
    end
  end
end
