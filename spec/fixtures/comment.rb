class Comment
  attr_accessor :id, :user_id, :text, :created_at

  def initialize(comment)
    @id = comment[:id].to_i
    @user_id = comment[:user_id].to_i
    @text = comment[:text]
    @created_at = comment[:created_at]
  end
end