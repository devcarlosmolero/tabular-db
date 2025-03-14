require "tabular-db"
require_relative "../../app/models/user"

namespace :csv do
  desc "create sample data for the csv database"
  task seed: :environment do
    db = TabularDB.new("/app/db")
    users = []

    100.times do |i|
      user_data = {
        id: i + 1,
        username: "user#{i + 1}",
        name: "User #{i + 1}",
        age: rand(18..65),
        email: "user#{i + 1}@example.com"
      }

      users << User.new(user_data)
    end

    db.create(users)

    puts "Users created"
  end
end