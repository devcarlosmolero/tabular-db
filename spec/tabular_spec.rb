require 'tabular'
require_relative "../lib/exceptions/tabular_error"
require_relative 'fixtures/user'
require_relative 'fixtures/comment'

RSpec.describe Tabular do
  FILES_ROOT = '/spec/fixtures'

  let(:tabular) { Tabular.new(FILES_ROOT) }

  before(:all) do
    t = Tabular.new(FILES_ROOT)
    t.drop(User)
    t.drop(Comment)
  end

  describe '#insert' do
    it 'insert should raise an error if the instances argument is not an array' do
      expect {
        tabular.insert(User.new({ user_id: 1, username: 'johndoe', email: 'john@doe.com', created_at: Time.now }))
      }.to raise_error(TabularError, 'TabularDB: insert accepts an array of instances')
    end

    it 'insert should raise an error if instances are from different classes' do
      expect {
        tabular.insert([
          User.new({ user_id: 1, username: 'johndoe', email: 'john@doe.com', created_at: Time.now }),
          Comment.new({ comment_id: 1, user_id: 1, comment_text: 'Something', created_at: Time.now })
        ])
      }.to raise_error(TabularError, 'TabularDB: all the instances passed to insert must be created from the same Class')
    end

    it 'insert should create a table if it does not exist' do
      tabular.insert([
        User.new({ user_id: 1, username: 'johndoe', email: 'john@doe.com', created_at: Time.now }),
      ])

      expect(tabular.table_exists?(User)).to be true
    end

    it 'insert should be able insert only 1 instance' do
      tabular.insert([
        User.new({ user_id: 2, username: 'johndoe2', email: 'john2@doe.com', created_at: Time.now }),
      ])

      expect(tabular.read(User)[:rows].count).to eq 2
    end

    it 'insert should be able insert more than 1 instance' do
      tabular.insert([
        User.new({ user_id: 3, username: 'johndoe3', email: 'john3@doe.com', created_at: Time.now }),
        User.new({ user_id: 4, username: 'johndoe4', email: 'john4@doe.com', created_at: Time.now }),
      ])

      expect(tabular.read(User)[:rows].count).to eq 4
    end
  end

  describe '#read' do
    it 'read should filter using where' do
        expect(tabular.read(User, nil, "instance.user_id == 1")[:rows].count).to eq 1
    end

    it 'read should filter using multiple where clauses' do
      expect(tabular.read(User, nil, "instance.user_id == 1 and instance.username == 'johndoe'")[:rows].count).to eq 1
    end
  end

  describe '#delete' do
    it 'delete should remove specific records in a table when a where clause is passed' do
      tabular.delete(User, "instance.user_id == 1 and instance.username == 'johndoe'")
      expect(tabular.read(User, nil, "instance.user_id == 1 and instance.username == 'johndoe'")[:rows].count).to eq 0
    end

    it 'delete should remove all records in a table when no where clause is passed' do
      tabular.delete(User)
      expect(tabular.read(User)[:rows].count).to eq 0
    end
  end
end
