# frozen_string_literal: true

require "active_record"
require "yaml"

module RailsBenchmarkSuite
  class DatabaseManager
    SETUP_MUTEX = Mutex.new

    def setup(use_local_db: false)
      # Silence migrations
      ActiveRecord::Migration.verbose = false

      if use_local_db
        setup_real_database
      else
        setup_sqlite_memory
      end
    end

    private

    def setup_real_database
      config_path = File.join(Dir.pwd, "config", "database.yml")
      unless File.exist?(config_path)
        raise "Database config not found at #{config_path} (required for --db option)"
      end

      db_config = YAML.load_file(config_path)
      env = defined?(Rails) ? Rails.env : "development"
      
      ActiveRecord::Base.establish_connection(db_config[env])
      puts "Connected to local database (#{env})"
    end

    def setup_sqlite_memory
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
      apply_sqlite_optimizations
    end

    def apply_sqlite_optimizations
      conn = ActiveRecord::Base.connection.raw_connection
      conn.execute("PRAGMA journal_mode = WAL")
      conn.execute("PRAGMA synchronous = NORMAL")
      conn.execute("PRAGMA mmap_size = 268435456") # 256MB - reduce disk I/O
    end
  end
end
