# frozen_string_literal: true

require "etc"

module RailsBenchmarkSuite
  class Configuration
    attr_accessor :threads, :profile, :db, :skip_rails, :json, :html

    def initialize
      @threads = Etc.nprocessors
      @profile = false
      @db = false
      @skip_rails = false
      @json = false
      @html = false
    end

    def db_mode
      @db ? "Local DB" : "SQLite (Memory)"
    end
  end
end
