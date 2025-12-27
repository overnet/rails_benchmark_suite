# Copyright (c) 2024 RailsBenchmarkSuite Contributors

require "active_record"
require "json"


RailsBenchmarkSuite.register_suite("Job Heft", weight: 0.3) do
  # Simulation: Enqueue 100 jobs, then work them off
  
  # 1. Enqueue Loop
  100.times do |i|
    RailsBenchmarkSuite::Models::SimulatedJob.create!(
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
      jobs = RailsBenchmarkSuite::Models::SimulatedJob.where("scheduled_at <= ?", Time.now).order(:created_at).limit(10)
      
      if jobs.any?
        # Simulate processing time and delete
        ids = jobs.map(&:id)
        RailsBenchmarkSuite::Models::SimulatedJob.where(id: ids).delete_all
        processed = true
      end
    end
    
    break unless processed
    
    # Tiny sleep to simulate latency of a real worker
    sleep(0.001)
  end
end
