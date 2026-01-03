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

    def render_summary_table(results)
      total_score = 0
      
      # Add spacing and separator before table
      puts "\n"
      puts "─" * 72
      puts ""
      
      # Table header
      printf "#{BOLD}%-28s %10s %10s %10s %7s#{RESET}\n", "Workload", "1T IPS", "4T IPS", "Scaling", "Weight"
      puts "─" * 72
      
      results.each do |data|
        report = data[:report]
        entries = report.entries
        
        entry_1t = entries.find { |e| e.label.include?("(1 thread)") }
        entry_4t = entries.find { |e| e.label.include?("(4 threads)") }
        
        ips_1t = entry_1t ? entry_1t.ips : 0
        ips_4t = entry_4t ? entry_4t.ips : 0
        
        scaling = ips_1t > 0 ? (ips_4t / ips_1t) : 0
        weight = data[:weight] || 1.0
        
        # Color scaling based on performance
        scaling_color = if scaling >= 0.6
          GREEN
        elsif scaling >= 0.3
          YELLOW
        else
          RED
        end
        
        # Heft Score: Weighted Sum of 4t IPS
        weighted_score = ips_4t * weight
        total_score += weighted_score
        
        printf "%-28s %10s %10s #{scaling_color}%9.2fx#{RESET} %7.1f\n",
          data[:name],
          humanize(ips_1t),
          humanize(ips_4t),
          scaling,
          weight
      end
      
      puts "─" * 72
      puts ""
      
      render_final_score(total_score)
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

    def as_json(results)
      out = {
        system: RailsBenchmarkSuite::Reporter.system_info,
        total_score: 0,
        workloads: []
      }
      
      total_score = 0
      
      results.each do |data|
        weight = data[:weight] || 1.0
        
        # Parse reports
        ips_1t = data[:report].entries.find { |e| e.label.include?("(1 thread)") }&.ips || 0
        ips_4t = data[:report].entries.find { |e| e.label.include?("(4 threads)") }&.ips || 0
        
        weighted_score = ips_4t * weight
        total_score += weighted_score
        
        out[:workloads] << {
          name: data[:name],
          weight: weight,
          ips_1t: ips_1t,
          ips_4t: ips_4t,
          scaling: ips_1t > 0 ? (ips_4t / ips_1t) : 0,
          memory_delta_mb: data[:memory_delta_mb],
          score: weighted_score
        }
      end
      
      out[:total_score] = total_score.round(0)
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
