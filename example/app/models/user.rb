class User
  attr_accessor :id, :username, :name, :age, :email
  def initialize(data)
    @id = data[:id].to_i
    @username = data[:username]
    @name = data[:name]
    @age = data[:age]
    @email = data[:email]
  end
end