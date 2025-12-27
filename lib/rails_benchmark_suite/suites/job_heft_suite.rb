# MIT License
# Copyright (c) 2024 RailsBenchmarkSuite Contributors

require "active_record"
require "json"

# Job Heft Schema
# Check table existence to avoid race conditions if reloaded, 
# though in this architecture it runs once.
unless ActiveRecord::Base.connection.table_exists?(:simulated_jobs)
  ActiveRecord::Schema.define do
    create_table :simulated_jobs, force: true do |t|
      t.string :queue_name
      t.text :arguments
      t.datetime :scheduled_at
      t.timestamps
    end
    add_index :simulated_jobs, [:queue_name, :scheduled_at]
  end
end

class SimulatedJob < ActiveRecord::Base
end

RailsBenchmarkSuite.register_suite("Job Heft", weight: 0.3) do
  # Simulation: Enqueue 100 jobs, then work them off
  
  # 1. Enqueue Loop
  100.times do |i|
    SimulatedJob.create!(
      queue_name: "default", 
      arguments: { job_id: i, payload: "x" * 100 }.to_json,
      scheduled_at: Time.now
    )
  end

  # 2. Worker Loop (Drain the queue)
  # Simulate a worker polling and claiming jobs
  loop do
    # Simulate worker latency & transactional safety
    processed = false
    
    ActiveRecord::Base.transaction do
      # Fetch batch (simplified Solid Queue polling style)
      jobs = SimulatedJob.where("scheduled_at <= ?", Time.now).order(:created_at).limit(10)
      
      if jobs.any?
        # Simulate processing time and delete
        ids = jobs.map(&:id)
        SimulatedJob.where(id: ids).delete_all
        processed = true
      end
    end
    
    break unless processed
    
    # Tiny sleep to simulate latency of a real worker
    sleep(0.001)
  end
end
