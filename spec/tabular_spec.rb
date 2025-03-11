require "tabular"
require_relative "fixtures/user"

RSpec.describe Tabular do
  let(:tabular) { Tabular.new("/spec/fixtures") }
  describe "#insert" do
    it "inserts a new row and, if the csv file doesn't exists, creates a new table" do
      tabular.insert(User.new({user_id: 1, username: "johndoe", email: "john@doe.com", created_at: Time.now}))
    end
  end
end
