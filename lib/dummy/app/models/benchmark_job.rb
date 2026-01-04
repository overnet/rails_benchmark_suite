module RailsBenchmarkSuite
  module Dummy
    class BenchmarkJob < ActiveRecord::Base
      self.table_name = "simulated_jobs" # Keep table name consistent or rename? Let's use simulated_jobs as it's descriptive
    end
  end
end
