require "action_view"
require "ostruct"

begin
  lookup_context = ActionView::LookupContext.new([Dir.pwd])
  view = ActionView::Base.with_empty_template_cache.new(lookup_context, {}, nil)
  
  template = "<h1><%= user.name %></h1>"
  user = OpenStruct.new(name: "Test")
  
  puts view.render(inline: template, locals: { user: user })
rescue => e
  puts "Error: #{e.class}: #{e.message}"
  puts e.backtrace
end
