# frozen_string_literal: true

require "active_record"
require "sqlite3"

# Silence ActiveRecord logs during benchmarks to avoid IO bottlenecks
ActiveRecord::Base.logger = nil

# Silence migration output
ActiveRecord::Migration.verbose = false
