# frozen_string_literal: true

# Request Heft Workload
# Benchmarks the full Rails request lifecycle (Middleware → Router → Controller → View)
# Uses ephemeral in-memory route injection - zero production footprint

RailsBenchmarkSuite::Runner.register_workload("Request Heft", weight: 0.3) do
  # Lazy-load Rails dependencies only when workload runs
  begin
    require "rails"
    require "action_controller/railtie"
  rescue LoadError
    next true # Skip gracefully if Rails not available
  end
  # Safety check: Skip if Rails.application unavailable (--skip-rails mode)
  next true unless defined?(Rails.application) && Rails.application

  begin
    # Step A: Define Ephemeral Controller
    # Anonymous class avoids constant pollution
    controller_class = Class.new(ActionController::Base) do
      layout false

      def index
        render plain: "OK"
      end
    end

    # Step B: Inject Ephemeral Route
    # Obscure path to avoid collisions with host app routes
    Rails.application.routes.draw do
      get "/_rbs_benchmark/heft", to: controller_class.action(:index)
    end

    # Step C: Execute Full-Stack Request
    env = Rack::MockRequest.env_for("/_rbs_benchmark/heft")
    status, _headers, _body = Rails.application.call(env)

    # Step D: Validation
    # Don't read/close body to avoid I/O overhead skewing benchmark
    raise RuntimeError, "Request Heft failed: status=#{status}" unless status == 200

    true
  rescue => e
    # Error handling - don't crash the entire suite
    warn "[Request Heft] Error: #{e.message}" if ENV["DEBUG"]
    false
  end
end
