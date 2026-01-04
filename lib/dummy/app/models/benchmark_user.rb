module RailsBenchmarkSuite
  module Dummy
    class BenchmarkUser < ActiveRecord::Base
      self.table_name = "benchmark_users"

      has_many :posts, class_name: "RailsBenchmarkSuite::Dummy::BenchmarkPost", foreign_key: "benchmark_user_id"
    end
  end
end
