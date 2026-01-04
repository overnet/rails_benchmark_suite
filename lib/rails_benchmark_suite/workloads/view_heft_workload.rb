# frozen_string_literal: true

require "action_view"
require "ostruct"

# Benchmark Workload


# Helper for the workload - Mixed into ActionView::Base instance automatically by Rails usually, 
# but here we might need to include it or just rely on standard helpers if ActionView loads them.
# The template uses number_with_delimiter which is standard.
module RailsBenchmarkSuiteNumberHelper
  # No-op or keep provided helper if standard library fails in isolation
end

  RailsBenchmarkSuite::Runner.register_workload("View Heft", weight: 0.2) do
    # Setup context once
    @view_renderer ||= begin
      # Use the "Dummy" app views folder
      views_path = File.expand_path("../../dummy/app/views", __dir__)
      lookup_context = ActionView::LookupContext.new([views_path])
      ActionView::Base.with_empty_template_cache.new(lookup_context, {}, nil)
    end
  
    # Workload: Render template from file
    # Previously inline, now isolated in lib/dummy/app/views

  
  # Dummy Objects
  user = OpenStruct.new(name: "Speedy")
  posts = 100.times.map { |i| OpenStruct.new(title: "Post #{i}", body: "Content " * 10, views: i * 1000) }

  # Execution
  # Render the namespaced template 'rails_benchmark_suite/heft_view'
  @view_renderer.render(template: "rails_benchmark_suite/heft_view", locals: { user: user, posts: posts })
end
