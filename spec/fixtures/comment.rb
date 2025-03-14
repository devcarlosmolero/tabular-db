class Comment
  attr_accessor :comment_id, :user_id, :comment_text, :created_at

  def initialize(comment)
    @comment_id = comment[:comment_id].to_i
    @user_id = comment[:user_id].to_i
    @comment_text = comment[:comment_text]
    @created_at = comment[:created_at]
  end
end
