# frozen_string_literal: true

require "active_record"

# Benchmark Workload
RailsBenchmarkSuite::Runner.register_workload("Active Record Heft", weight: 0.4) do
  # Workload: Create User with Posts, Join Query, Update
  # Use transaction rollback to keep the DB clean and avoid costly destroy callbacks
  ActiveRecord::Base.transaction do
    # 1. Create - with unique email per thread
    user = RailsBenchmarkSuite::Dummy::BenchmarkUser.create!(
      name: "Benchmark User", 
      email: "test-#{Thread.current.object_id}@example.com"
    )
    
    # 2. Create associated records (simulate some weight)
    10.times do |i|
      user.posts.create!(title: "Post #{i}", body: "Content " * 50)
    end
    
    # 3. Complex Query (Join + Order)
    # Unloading the relation to force execution
    RailsBenchmarkSuite::Dummy::BenchmarkUser.joins(:posts)
                .where(benchmark_users: { id: user.id })
                .where("benchmark_posts.views >= ?", 0)
                .order("benchmark_posts.created_at DESC")
                .to_a
    
    # 4. Update
    user.update!(name: "Updated User")
    
    # Rollback everything to leave the DB clean for next iteration
    raise ActiveRecord::Rollback
  end
end
