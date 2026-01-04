# frozen_string_literal: true

require "erb"
require "json"
require "fileutils"

module RailsBenchmarkSuite
  module Reporters
    class HtmlReporter
      def initialize(payload)
        @payload = payload
      end

      def generate
        template_path = File.expand_path("../templates/report.html.erb", __dir__)
        template = File.read(template_path)
        
        # Prepare data for JS injection (Flatten complex objects to simple Hash)
        chart_data = {
          labels: @payload[:results].map { |r| r[:name] },
          data_1t: [],
          data_mt: []
        }

        @payload[:results].each do |res|
          entry_1t = res[:report].entries.find { |e| e.label.include?("(1 thread)") }
          entry_mt = res[:report].entries.find { |e| e.label.match?(/\(\d+ threads\)/) }
          
          chart_data[:data_1t] << (entry_1t ? entry_1t.ips : 0)
          chart_data[:data_mt] << (entry_mt ? entry_mt.ips : 0)
        end

        @chart_payload = chart_data.to_json
        
        # Render
        html = ERB.new(template).result(binding)
        
        # Output file
        dir = Dir.exist?("tmp") ? "tmp" : "."
        file_path = File.join(dir, "rails_benchmark_report.html")
        File.write(file_path, html)
        
        puts "\n"
        puts "✅ HTML Report Generated!"
        puts "📂 Location: #{File.expand_path(file_path)}"
        puts "👉 View (Local):  open '#{file_path}'"
        puts "👉 View (Remote): scp user@server:#{File.expand_path(file_path)} ."
        puts "\n"
      end
    end
  end
end
