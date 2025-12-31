# MIT License
# Copyright (c) 2024 RailsBenchmarkSuite Contributors

# Benchmark Suite
# Benchmark standard ActiveRecord querying (LIKE operations) as a proxy for search performance.

RailsBenchmarkSuite.register_suite("Search Heft", weight: 0.1) do
  # Ensure test data exists
  unless defined?(@search_data_seeded)
    if RailsBenchmarkSuite::Models::Post.count < 100
      user = RailsBenchmarkSuite::Models::User.first || RailsBenchmarkSuite::Models::User.create!(name: "Searcher")
      100.times { |i| user.posts.create!(title: "Unique Title #{i}", body: "Searchable Content " * 20) }
    end
    @search_data_seeded = true
  end

  # Workload: Complex queries on indexed columns
  # 1. Exact Match
  RailsBenchmarkSuite::Models::Post.where(title: "Unique Title 50").load
  
  # 2. Prefix Match
  RailsBenchmarkSuite::Models::Post.where("title LIKE ?", "Unique Title 5%").load
  
  # 3. Wildcard Search
  RailsBenchmarkSuite::Models::Post.where("body LIKE ?", "%Searchable%").limit(10).load
end
