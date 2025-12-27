# MIT License
# Copyright (c) 2024 RailsBenchmarkSuite Contributors

require "active_record"

# Schema Definition
ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :name
    t.string :email
    t.timestamps
  end

  create_table :posts, force: true do |t|
    t.references :user
    t.string :title
    t.text :body
    t.integer :views, default: 0
    t.timestamps
  end
end

# Models
class User < ActiveRecord::Base
  has_many :posts
end

class Post < ActiveRecord::Base
  belongs_to :user
end

# Benchmark Suite
RailsBenchmarkSuite.register_suite("Active Record Heft", weight: 0.7) do
  # Workload: Create User with Posts, Join Query, Update
  
  # 1. Create
  user = User.create!(name: "Speedy Gonzales", email: "speedy@example.com")
  
  # 2. Create associated records (simulate some weight)
  10.times do |i|
    user.posts.create!(title: "Post #{i}", body: "Content " * 50)
  end
  
  # 3. Complex Query (Join + Order)
  # Unloading the relation to force execution
  posts = User.joins(:posts)
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
