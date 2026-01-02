# frozen_string_literal: true

require "active_record"

module RailsBenchmarkSuite
  module Schema
    def self.load
      ActiveRecord::Schema.define do
        # Users
        create_table :users, force: true do |t|
          t.string :name
          t.string :email
          t.timestamps
        end

        # Posts
        create_table :posts, force: true do |t|
          t.references :user
          t.string :title
          t.text :body
          t.integer :views, default: 0
          t.timestamps
        end

        # Simulated Jobs (for Job Heft)
        create_table :simulated_jobs, force: true do |t|
          t.string :queue_name
          t.text :arguments
          t.datetime :scheduled_at
          t.timestamps
        end
        add_index :simulated_jobs, [:queue_name, :scheduled_at]
      end
    end
  end
end
