require 'tabular-db'
require_relative 'fixtures/user'
require_relative 'fixtures/comment'
require_relative "../lib/tabular_db_error"

RSpec.describe TabularDB do
  FILES_ROOT = '/spec/fixtures'
  let(:tabular) { TabularDB.new(FILES_ROOT) }

  before(:each) do
    db = TabularDB.new("/spec/fixtures")
    db.drop(User)
    db.drop(Comment)

    users = []

    129.times do |i|
      user_data = {
        id: i + 1,
        username: "@#{Faker::Name.name.split(" ").join("").downcase}",
        name: Faker::Name.name,
        address: Faker::Address.full_address,
        email: "user#{i + 1}@example.com",
        created_at: Time.now
      }
      users << User.new(user_data)
    end

    db.create(users)
  end

  describe '#create' do
    it 'create should raise an error if the instances argument is not an array' do
      expect {
        tabular.create(User.new({ id: 130, username: '@johndoe', name: "John Doe", address: "Some Street, California, USA", email: 'john@doe.com', created_at: Time.now }))
      }.to raise_error(TabularDBError, 'TabularDB: instances must be an array')
    end

    it 'create should raise an error if instances are from different classes' do
      expect {
        tabular.create([
          User.new({ id: 130, username: '@johndoe', name: "John Doe", address: "Some Street, California, USA", email: 'john@doe.com', created_at: Time.now }),
          Comment.new({ id: 1, user_id: 1, text: 'Something', created_at: Time.now })
        ])
      }.to raise_error(TabularDBError, 'TabularDB: all the instances must be created from the same Class')
    end

    it 'create should create a table if it does not exist' do
      tabular.create([
        Comment.new({ id: 1, user_id: 1, text: 'Something', created_at: Time.now }),
      ])

      expect(tabular.table_exist?(Comment)).to be true
    end

    it 'create should be able to create only 1 instance' do
      tabular.create([
        User.new({ id: 130, username: '@johndoe', name: "John Doe", address: "Some Street, California, USA", email: 'john@doe.com', created_at: Time.now }),
      ])

      expect(tabular.read(User, {
        where: "row['username'] == '@johndoe'"
      })[:rows].count).to eq 1
    end

    it 'create should be able to create more than 1 instance' do
      tabular.create([
        User.new({ id: 130, username: '@johndoe', name: "John Doe", address: "Some Street, California, USA", email: 'john@doe.com', created_at: Time.now }),
        User.new({ id: 131, username: '@johndoe2', name: "John Doe 2", address: "Some Street, California, USA", email: 'john2@doe.com', created_at: Time.now }),
      ])

      expect(tabular.read(User, {
        where: "row['address'] == 'Some Street, California, USA'"
      })[:rows].count).to eq 2
    end
  end

  describe '#read' do
    it 'read should filter using where' do
        expect(tabular.read(User, {
          where: "row['id'].to_i == 1"
        })[:rows].count).to eq 1
    end


    it 'read should filter using multiple where clauses' do
      tabular.create([
        User.new({ id: 130, username: '@johndoe', name: "John Doe", address: "Some Street, California, USA", email: 'john@doe.com', created_at: Time.now }),
      ])

      expect(tabular.read(User, {
        where: "row['id'].to_i == 130 and row['username'] == '@johndoe'"
      })[:rows].count).to eq 1
    end

    it 'read should return the header and the rows' do
      tabular.create([
        User.new({ id: 130, username: '@johndoe', name: "John Doe", address: "Some Street, California, USA", email: 'john@doe.com', created_at: Time.now }),
      ])

      data = tabular.read(User, {
        where: "row['id'].to_i == 130 and row['username'] == '@johndoe'"
      })

      expect(data[:header].count).to eq 6
      expect(data[:rows].count).to eq 1
    end

    it 'read should return the paginated rows' do
      data = tabular.read(User, {
        limit: 20,
        offset: 20
      })

      expect(data[:rows].count).to eq 20
      expect(data[:total_count]).to eq 129
      expect(data[:has_prev]).to be true
      expect(data[:has_next]).to be true
    end

    it 'read should sort' do
      expect(tabular.read(User, {
        sort: "row['id'].to_i * 1"
      })[:rows].first["id"]).to eq "1"

      expect(tabular.read(User, {
        sort: "row['id'].to_i * -1"
      })[:rows].first["id"]).to eq "129"
    end
  end

  describe '#update' do
    it 'update should raise an error if there is no where clause' do
      expect {
        tabular.update(User)
      }.to raise_error(TabularDBError, 'TabularDB: where argument is required for update operations')
    end

    it 'update should raise an error if there is no updated_values' do
      expect {
        tabular.update(User, {
          where: "row['id'].to_i == 1"
        })
      }.to raise_error(TabularDBError, 'TabularDB: updated_values argument is required for update operations')
    end

    it 'update should be able to update a single record' do
      data = tabular.update(User, "row['id'].to_i == 1", { user_id: 130 })
      expect(data[:rows].count).to eq 1
    end

    it 'update should be able to update a multiple records' do
      tabular.create([
        User.new({ id: 130, username: '@johndoe', name: "John Doe", address: "Some Street, California, USA", email: 'john@doe.com', created_at: Time.now }),
        User.new({ id: 131, username: '@johndoe2', name: "John Doe 2", address: "Some Street, California, USA", email: 'john2@doe.com', created_at: Time.now }),
      ])
      data = tabular.update(User, "row['address'] == 'Some Street, California, USA'", { address: "New Address" })
      expect(data[:rows].count).to eq 2
    end
  end

  describe '#delete' do
    it 'delete should remove specific records in a table when a where clause is passed' do
      tabular.delete(User, "row['id'].to_i == 1")
      expect(tabular.read(User, {
        where: "row['id'].to_i == 1"
      })[:rows].count).to eq 0
    end

    it 'delete should remove all records in a table when no where clause is passed' do
      tabular.delete(User)
      expect(tabular.read(User, {})[:rows].count).to eq 0
    end
  end
end
