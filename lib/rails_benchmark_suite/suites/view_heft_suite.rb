# MIT License
# Copyright (c) 2024 RailsBenchmarkSuite Contributors

require "action_view"
require "ostruct"

# Benchmark Suite


# Helper for the suite
module RailsBenchmarkSuiteNumberHelper
  def self.number_with_delimiter(number)
    number.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1,")
  end
end

  RailsBenchmarkSuite.register_suite("View Heft", weight: 0.2) do
    # Setup context once
    @view_renderer ||= begin
      lookup_context = ActionView::LookupContext.new([File.expand_path(__dir__)])
      ActionView::Base.with_empty_template_cache.new(lookup_context, {}, nil)
    end
  
    # Workload: Render a complex ERB template
    template = <<~ERB
    <h1>Dashboard for <%= user.name %></h1>
    <ul>
      <% posts.each do |post| %>
        <li>
          <strong><%= post.title %></strong>
          <p><%= post.body.truncate(50) %></p>
          <small>Views: <%= RailsBenchmarkSuiteNumberHelper.number_with_delimiter(post.views) %></small>
        </li>
      <% end %>
    </ul>
    <footer>Generated at <%= Time.now.to_s %></footer>
  ERB
  
  # Dummy Objects
  user = OpenStruct.new(name: "Speedy")
  posts = 50.times.map { |i| OpenStruct.new(title: "Post #{i}", body: "Content " * 10, views: i * 1000) }

  # Execution
  @view_renderer.render(inline: template, locals: { user: user, posts: posts })
end
