# MIT License
# Copyright (c) 2024 RailsBenchmarkSuite Contributors

module RailsBenchmarkSuite
  module Models
    class User < ActiveRecord::Base
      has_many :posts, class_name: "RailsBenchmarkSuite::Models::Post", dependent: :destroy
    end
  end
end
