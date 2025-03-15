require "tabular-db"
require "faker"
require_relative "../../app/models/user"

namespace :csv do
  desc "create sample data for the csv database"
  task seed: :environment do
    db = TabularDB.new("/app/db")
    users = []

    129.times do |i|
      user_data = {
        id: i + 1,
        username: "@#{Faker::Name.name.split(" ").join("").downcase}",
        name: Faker::Name.name,
        age: rand(18..65),
        email: "user#{i + 1}@example.com"
      }

      users << User.new(user_data)
    end

    db.create(users)
  end
end