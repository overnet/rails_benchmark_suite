# frozen_string_literal: true

require "json"
require "tty-table"
require "tty-box"
require "pastel"

require "tty-cursor"

module RailsBenchmarkSuite
  module Formatter
    module_function
    
    def pastel
      @pastel ||= Pastel.new
    end

    def cursor
      @cursor ||= TTY::Cursor
    end

    def header(info)
      print cursor.hide
      # Build YJIT Status
      yjit_status = info[:yjit] ? pastel.green("ON") : pastel.red("OFF")
      yjit_hint = info[:yjit] ? "" : " (use RUBY_OPT=\"--yjit\")"
      
      content = [
        "System: #{info[:processors]} Cores | Ruby #{info[:ruby_version]}",
        "DB: SQLite (Memory) | YJIT: #{yjit_status}#{yjit_hint}"
      ].join("\n")

      print TTY::Box.frame(
        width: 80, 
        title: { top_left: " Rails Benchmark Suite v#{RailsBenchmarkSuite::VERSION} " },
        padding: 1,
        style: {
          fg: :white,
          border: { fg: :bright_blue }
        }
      ) { content }
      puts ""
    end

    # Progress is now handled by Spinners in WorkloadRunner directly
    def render_progress(num, total, name, state)
      # Legacy support or no-op since spinners handle this now
    end

    def summary_with_insights(payload)
      results = payload[:results]
      total_score = payload[:total_score]
      tier = payload[:tier]
      threads = payload[:threads] || 4
      
      puts ""
      
      # 1. Comparison Table
      rows = results.map do |data|
        report = data[:report]
        entries = report.entries
        
        entry_1t = entries.find { |e| e.label.include?("(1 thread)") }
        entry_mt = entries.find { |e| e.label.match?(/\(\d+ threads\)/) }
        
        ips_1t = entry_1t ? entry_1t.ips : 0
        ips_mt = entry_mt ? entry_mt.ips : 0
        
        scaling = ips_1t > 0 ? (ips_mt / ips_1t) : 0
        efficiency = (ips_mt / (ips_1t * threads)) * 100 if ips_1t > 0 && threads > 0
        efficiency ||= 0
        
        # Color coding
        eff_color = if efficiency >= 75
          :green
        elsif efficiency >= 50
          :yellow
        else
          :red
        end

        [
          data[:name],
          humanize(ips_1t),
          humanize(ips_mt),
          pastel.decorate("#{efficiency.round(1)}%", eff_color),
          data[:adjusted_weight].round(2)
        ]
      end

      table = TTY::Table.new(
        header: ["Workload", "1T IPS", "#{threads}T IPS", "Efficiency", "Weight"], 
        rows: rows
      )
      
      puts table.render(:unicode, padding: [0, 1]) do |renderer|
        renderer.border.separator = :each_row
        renderer.border.style = :blue
      end
      
      # 2. Insights List
      puts ""
      check_scaling_insights(results)
      check_yjit_insight
      check_memory_insights(results)
      
      # 3. Final Score Dashboard
      render_final_score(total_score)
      show_hardware_tier(tier)
    end

    def check_scaling_insights(results)
      poor_scaling = results.select do |r|
        entries = r[:report].entries
        entry_1t = entries.find { |e| e.label.include?("(1 thread)") }
        entry_mt = entries.find { |e| e.label.match?(/\(\d+ threads\)/) }
        
        ips_1t = entry_1t ? entry_1t.ips : 0
        ips_mt = entry_mt ? entry_mt.ips : 0 
        scaling = ips_1t > 0 ? (ips_mt / ips_1t) : 0
        scaling < 0.8
      end
      
      if poor_scaling.any?
        puts pastel.yellow.bold("💡 Insight (Scaling):") + " Scaling below 1.0x detected."
        puts "   This indicates SQLite lock contention or Ruby GIL saturation."
      end
    end

    def check_yjit_insight
      unless defined?(RubyVM::YJIT) && RubyVM::YJIT.enabled?
        puts ""
        puts pastel.yellow.bold("💡 Insight (YJIT):") + " YJIT is OFF."
        puts "   Run with RUBY_OPT=\"--yjit\" for ~20% boost."
      end
    end

    def check_memory_insights(results)
      results.select { |r| r[:memory_delta_mb] > 20 }.each do |r|
        puts ""
        puts pastel.yellow.bold("💡 Insight (Memory):") + " High growth in #{r[:name]} (#{r[:memory_delta_mb].round(1)}MB)"
        puts "   Suggests heavy object allocation."
      end
    end

    def show_hardware_tier(tier)
      comparison = case tier
      when "Entry/Dev"
        "Entry-Level (Suitable for dev/testing)"
      when "Production-Ready"
        "Professional-Grade (Matches dedicated instances)"
      else
        "High-Performance (Bare-metal speed)"
      end
      
      puts ""
      puts pastel.bold("📊 Performance Tier: ") + comparison
      puts ""
      print cursor.show
    end

    def render_final_score(score)
      score_str = "#{score.round(0)}"
      puts ""
      
      print TTY::Box.frame(
        width: 40,
        height: 5,
        align: :center,
        padding: 1,
        title: { top_left: " RAILS HEFT INDEX " },
        style: { border: { fg: :green }, fg: :green }
      ) {
        pastel.bold(score_str)
      }
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
        entry_mt = entries.find { |e| e.label.match?(/\(\d+ threads\)/) }
        
        ips_1t = entry_1t ? entry_1t.ips : 0
        ips_mt = entry_mt ? entry_mt.ips : 0
        
        out[:workloads] << {
          name: data[:name],
          adjusted_weight: data[:adjusted_weight],
          ips_1t: ips_1t,
          ips_mt: ips_mt,
          threads: payload[:threads],
          scaling: ips_1t > 0 ? (ips_mt / ips_1t) : 0,
          efficiency: data[:efficiency],
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
