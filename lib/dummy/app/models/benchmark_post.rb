module RailsBenchmarkSuite
  module Dummy
    class BenchmarkPost < ActiveRecord::Base
      self.table_name = "benchmark_posts"

      belongs_to :user, class_name: "RailsBenchmarkSuite::Dummy::BenchmarkUser", foreign_key: "benchmark_user_id"
    end
  end
end
