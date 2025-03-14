require 'tabular-db'
require_relative 'fixtures/user'
require_relative 'fixtures/comment'
require_relative "../lib/tabular_db_error"

RSpec.describe TabularDB do
  FILES_ROOT = '/spec/fixtures'

  let(:tabular) { TabularDB.new(FILES_ROOT) }

  before(:all) do
    t = TabularDB.new(FILES_ROOT)
    t.drop(User)
    t.drop(Comment)
  end

  describe '#create' do
    it 'create should raise an error if the instances argument is not an array' do
      expect {
        tabular.create(User.new({ user_id: 1, username: 'johndoe', email: 'john@doe.com', created_at: Time.now }))
      }.to raise_error(TabularDBError, 'TabularDB: instances must be an array')
    end

    it 'create should raise an error if instances are from different classes' do
      expect {
        tabular.create([
          User.new({ user_id: 1, username: 'johndoe', email: 'john@doe.com', created_at: Time.now }),
          Comment.new({ comment_id: 1, user_id: 1, comment_text: 'Something', created_at: Time.now })
        ])
      }.to raise_error(TabularDBError, 'TabularDB: all the instances must be created from the same Class')
    end

    it 'create should create a table if it does not exist' do
      tabular.create([
        User.new({ user_id: 1, username: 'johndoe', email: 'john@doe.com', created_at: Time.now }),
      ])

      expect(tabular.table_exist?(User)).to be true
    end

    it 'create should be able to create only 1 instance' do
      tabular.create([
        User.new({ user_id: 2, username: 'johndoe2', email: 'john2@doe.com', created_at: Time.now }),
      ])

      expect(tabular.read(User)[:rows].count).to eq 2
    end

    it 'create should be able to create more than 1 instance' do
      tabular.create([
        User.new({ user_id: 3, username: 'johndoe3', email: 'john3@doe.com', created_at: Time.now }),
        User.new({ user_id: 4, username: 'johndoe4', email: 'john4@doe.com', created_at: Time.now }),
      ])

      expect(tabular.read(User)[:rows].count).to eq 4
    end
  end

  describe '#read' do
    it 'read should filter using where' do
        expect(tabular.read(User, "instance.user_id == 1")[:rows].count).to eq 1
    end

    it 'read should filter using multiple where clauses' do
      expect(tabular.read(User, "instance.user_id == 1 and instance.username == 'johndoe'")[:rows].count).to eq 1
    end

    it 'read should return the header and the rows' do
      expect(tabular.read(User, "instance.user_id == 1 and instance.username == 'johndoe'")[:header].count).to eq 4
      expect(tabular.read(User, "instance.user_id == 1 and instance.username == 'johndoe'")[:rows].count).to eq 1
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
        tabular.update(User, "instance.user_id == 1")
      }.to raise_error(TabularDBError, 'TabularDB: updated_values argument is required for update operations')
    end

    it 'update should be able to update a single record' do
      tabular.update(User, "instance.user_id == 1", { user_id: 22 })
      expect(tabular.read(User, "instance.user_id == 22")[:rows].count).to eq 1
    end

    it 'update should be able to update a multiple records' do
      tabular.update(User, "instance.user_id == 1 or instance.user_id == 2", { user_id: 22 })
      expect(tabular.read(User, "instance.user_id == 22")[:rows].count).to eq 2
    end

    it 'update should return the updated records' do
      result = tabular.update(User, "instance.user_id == 3 or instance.user_id == 4", { user_id: 22 })
      expect(result[:rows][0]["user_id"]).to eq 22
      expect(result[:rows][1]["user_id"]).to eq 22
    end
  end

  describe '#delete' do
    it 'delete should remove specific records in a table when a where clause is passed' do
      tabular.delete(User, "instance.user_id == 1 and instance.username == 'johndoe'")
      expect(tabular.read(User, "instance.user_id == 1 and instance.username == 'johndoe'")[:rows].count).to eq 0
    end

    it 'delete should remove all records in a table when no where clause is passed' do
      tabular.delete(User)
      expect(tabular.read(User)[:rows].count).to eq 0
    end
  end
end
