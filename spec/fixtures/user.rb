class User
  attr_accessor :user_id, :username, :email, :created_at

  def initialize(user)
    @user_id = user[:user_id].to_i
    @username = user[:username]
    @email = user[:email]
    @created_at = user[:created_at]
  end
end
