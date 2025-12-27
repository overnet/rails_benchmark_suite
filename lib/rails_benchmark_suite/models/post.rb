# MIT License
# Copyright (c) 2024 RailsBenchmarkSuite Contributors

module RailsBenchmarkSuite
  module Models
    class Post < ActiveRecord::Base
      belongs_to :user, class_name: "RailsBenchmarkSuite::Models::User"
    end
  end
end
