# frozen_string_literal: true

require "json"

module RailsBenchmarkSuite
  module Formatter
    # ANSI Color Codes
    RED = "\e[31m"
    YELLOW = "\e[33m"
    GREEN = "\e[32m"
    BLUE = "\e[34m"
    BOLD = "\e[1m"
    RESET = "\e[0m"

    module_function

    def header(info)
      box_width = 60  # Internal width
      
      # Line 1: Simple text
      line1 = "Rails Heft Index (RHI) v0.3.0"
      
      # Line 2: Build without colors first to measure
      yjit_status = info[:yjit] ? 'ON' : 'OFF'
      yjit_hint_text = info[:yjit] ? "" : " (use RUBY_OPT=\"--yjit\")"
      line2_plain = "Ruby #{info[:ruby_version]} • #{info[:processors]} Cores • YJIT: #{yjit_status}#{yjit_hint_text}"
      
      # Now build with colors
      yjit_color = info[:yjit] ? GREEN : RED
      yjit_hint_colored = info[:yjit] ? "" : " #{YELLOW}(use RUBY_OPT=\"--yjit\")#{RESET}"
      line2 = "Ruby #{info[:ruby_version]} • #{info[:processors]} Cores • YJIT: #{yjit_color}#{yjit_status}#{RESET}#{yjit_hint_colored}"
      
      puts "\n"
      puts "#{BLUE}┌#{'─' * box_width}┐#{RESET}"
      puts "#{BLUE}│#{RESET}  #{BOLD}#{line1}#{RESET}#{' ' * (box_width - 2 - line1.length)}#{BLUE}│#{RESET}"
      puts "#{BLUE}│#{RESET}  #{line2}#{' ' * (box_width - 2 - line2_plain.length)}#{BLUE}│#{RESET}"
      puts "#{BLUE}└#{'─' * box_width}┘#{RESET}"
      puts ""
    end

    def render_progress(num, total, name, state)
      if state == "Running"
        print "[#{num}/#{total}] Running #{name}... "
      else
        puts state
      end
    end

    def summary_with_insights(payload)
      results = payload[:results]
      total_score = payload[:total_score]
      tier = payload[:tier]
      
      # Add spacing and separator before table
      puts "\n"
      puts "─" * 72
      puts ""
      
      # Table header
      printf "#{BOLD}%-28s %10s %10s %10s %7s#{RESET}\n", "Workload", "1T IPS", "4T IPS", "Scaling", "Weight"
      puts "─" * 72
      
      # Table rows
      results.each do |data|
        report = data[:report]
        entries = report.entries
        
        entry_1t = entries.find { |e| e.label.include?("(1 thread)") }
        entry_4t = entries.find { |e| e.label.include?("(4 threads)") }
        
        ips_1t = entry_1t ? entry_1t.ips : 0
        ips_4t = entry_4t ? entry_4t.ips : 0
        
        scaling = ips_1t > 0 ? (ips_4t / ips_1t) : 0
        
        # Color scaling based on performance
        scaling_color = if scaling >= 0.6
          GREEN
        elsif scaling >= 0.3
          YELLOW
        else
          RED
        end
        
        printf "%-28s %10s %10s #{scaling_color}%9.2fx#{RESET} %7.1f\n",
          data[:name],
          humanize(ips_1t),
          humanize(ips_4t),
          scaling,
          data[:adjusted_weight]
      end
      
      # Display insights
      check_scaling_insights(results)
      check_yjit_insight
      check_memory_insights(results)
      
      # Display final score
      render_final_score(total_score)
      
      # Display tier comparison
      show_hardware_tier(tier)
    end

    def check_scaling_insights(results)
      #Extract scaling from results
      poor_scaling = results.select do |r|
        entries = r[:report].entries
        entry_1t = entries.find { |e| e.label.include?("(1 thread)") }
        entry_4t = entries.find { |e| e.label.include?("(4 threads)") }
        ips_1t = entry_1t ? entry_1t.ips : 0
        ips_4t = entry_4t ? entry_4t.ips : 0
        scaling = ips_1t > 0 ? (ips_4t / ips_1t) : 0
        scaling < 0.8
      end
      
      if poor_scaling.any?
        puts "\n💡 Insight (Scaling): Scaling below 1.0x detected."
        puts "   This indicates SQLite lock contention or Ruby GIL saturation."
      end
    end

    def check_yjit_insight
      unless defined?(RubyVM::YJIT) && RubyVM::YJIT.enabled?
        puts "\n💡 Insight (YJIT): YJIT is OFF."
        puts "   Run with RUBY_OPT=\"--yjit\" for ~20% boost."
      end
    end

    def check_memory_insights(results)
      high_memory = results.select { |r| r[:memory_delta_mb] > 20 }
      high_memory.each do |r|
        puts "\n💡 Insight (Memory): High growth in #{r[:name]} (#{r[:memory_delta_mb].round(1)}MB)"
        puts "   Suggests heavy object allocation."
      end
    end

    def show_hardware_tier(tier)
      comparison = case tier
      when "Entry/Dev"
        "📊 Performance Tier: Entry-Level (Suitable for dev/testing, may struggle with high production traffic)"
      when "Production-Ready"
        "📊 Performance Tier: Professional-Grade (Matches the throughput of dedicated production cloud instances)"
      else
        "📊 Performance Tier: High-Performance (Exceptional throughput, comparable to bare-metal or high-end workstations)"
      end
      
      puts "\n#{comparison}\n"
    end

    def render_final_score(score)
      box_width = 60  # Same as header
      
      # Build text without colors to measure
      score_text = "RAILS HEFT INDEX (RHI): #{score.round(0)}"
      
      # Build with colors
      score_colored = "#{GREEN}#{BOLD}RAILS HEFT INDEX (RHI): #{score.round(0)}#{RESET}"
      
      puts ""
      puts "#{BLUE}┌#{'─' * box_width}┐#{RESET}"
      puts "#{BLUE}│#{RESET}  #{score_colored}#{' ' * (box_width - 2 - score_text.length)}#{BLUE}│#{RESET}"
      puts "#{BLUE}└#{'─' * box_width}┘#{RESET}"
      puts ""
    end

    def as_json(payload)
      out = {
        system: RailsBenchmarkSuite::Reporter.system_info,
        total_score: payload[:total_score].round(0),
        tier: payload[:tier],
        workloads: []
      }
      
      payload[:results].each do |data|
        entries = data[:report].entries
        entry_1t = entries.find { |e| e.label.include?("(1 thread)") }
        entry_4t = entries.find { |e| e.label.include?("(4 threads)") }
        ips_1t = entry_1t ? entry_1t.ips : 0
        ips_4t = entry_4t ? entry_4t.ips : 0
        
        out[:workloads] << {
          name: data[:name],
          adjusted_weight: data[:adjusted_weight],
          ips_1t: ips_1t,
          ips_4t: ips_4t,
          scaling: ips_1t > 0 ? (ips_4t / ips_1t) : 0,
          memory_delta_mb: data[:memory_delta_mb]
        }
      end
      
      puts out.to_json
    end

    def humanize(ips)
      return "0" if ips.nil? || ips == 0
      if ips >= 1_000_000
        "#{(ips / 1_000_000.0).round(1)}M"
      elsif ips >= 1_000
        "#{(ips / 1_000.0).round(1)}k"
      else
        ips.round(1).to_s
      end
    end
  end
end
