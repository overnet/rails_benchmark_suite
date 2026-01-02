# frozen_string_literal: true

module RailsBenchmarkSuite
  module Models
    class Post < ActiveRecord::Base
      belongs_to :user, class_name: "RailsBenchmarkSuite::Models::User"
    end
  end
end
