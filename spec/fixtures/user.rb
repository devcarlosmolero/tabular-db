class User
  attr_accessor :id, :username, :name, :address, :email, :created_at

  def initialize(user)
    @id = user[:id].to_i
    @username = user[:username]
    @name = user[:name]
    @address = user[:address]
    @email = user[:email]
    @created_at = user[:created_at]
  end
end
