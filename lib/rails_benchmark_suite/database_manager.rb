# frozen_string_literal: true

require "active_record"

module RailsBenchmarkSuite
  class DatabaseManager
    SETUP_MUTEX = Mutex.new

    def setup
      # Silence migrations
      ActiveRecord::Migration.verbose = false

      # Ultimate Hardening: Massive pool and timeout for zero lock contention (v0.3.0)
      ActiveRecord::Base.establish_connection(
        adapter: "sqlite3",
        database: "file:heft_db?mode=memory&cache=shared",
        pool: 50,
        timeout: 30000
      )

      # The 'Busy Timeout' Hammer - force it directly on the raw connection
      ActiveRecord::Base.connection.raw_connection.busy_timeout = 10000
      
      # Setup Schema once safely with Mutex
      SETUP_MUTEX.synchronize do
        # Verify if schema already loaded by checking for a table
        unless ActiveRecord::Base.connection.table_exists?(:users)
          RailsBenchmarkSuite::Schema.load
        end
      end

      # High-Performance Pragmas for WAL + NORMAL sync
      ActiveRecord::Base.connection.raw_connection.execute("PRAGMA journal_mode = WAL")
      ActiveRecord::Base.connection.raw_connection.execute("PRAGMA synchronous = NORMAL")
      ActiveRecord::Base.connection.raw_connection.execute("PRAGMA mmap_size = 268435456") # 256MB - reduce disk I/O
    end
  end
end
