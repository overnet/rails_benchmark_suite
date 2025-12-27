# Copyright (c) 2024 RailsBenchmarkSuite Contributors

require "active_record"

# Benchmark Suite
RailsBenchmarkSuite.register_suite("Active Record Heft", weight: 0.7) do
  # Workload: Create User with Posts, Join Query, Update
  
  # 1. Create
  user = RailsBenchmarkSuite::Models::User.create!(name: "Speedy Gonzales", email: "speedy@example.com")
  
  # 2. Create associated records (simulate some weight)
  10.times do |i|
    user.posts.create!(title: "Post #{i}", body: "Content " * 50)
  end
  
  # 3. Complex Query (Join + Order)
  # Unloading the relation to force execution
  posts = RailsBenchmarkSuite::Models::User.joins(:posts)
              .where(users: { id: user.id })
              .where("posts.views >= ?", 0)
              .order("posts.created_at DESC")
              .to_a
  
  # 4. Update
  user.update!(name: "Slowpoke Rodriguez")
  
  # Cleanup (optional for Heft, but prevents memory ballooning in long runs)
  # But for benchmark-ips, we should likely not do excessive cleanup 
  # inside the measured block unless it's part of the lifecycle we want to measure.
  # However, creating DB records endlessly will eat RAM.
  # Let's clean up for this micro-benchmark to keep it stable.
  user.destroy
end
