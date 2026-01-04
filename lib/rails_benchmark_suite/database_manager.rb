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
        setup_dummy_database
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

    def setup_dummy_database
      # Load internal dummy config
      config_path = File.expand_path("../dummy/config/benchmark_database.yml", __dir__)
      db_config = YAML.load_file(config_path)
      
      # Use "development" profile which has the PRAGMA optimizations
      ActiveRecord::Base.establish_connection(db_config["development"])

      # Apply manual optimizations if needed (though config should handle it)
      conn = ActiveRecord::Base.connection.raw_connection
      conn.busy_timeout = 10000
      
      # Setup Schema once safely
      SETUP_MUTEX.synchronize do
        unless ActiveRecord::Base.connection.table_exists?(:benchmark_users)
          RailsBenchmarkSuite::Schema.load
        end
      end
    end
  end
end
