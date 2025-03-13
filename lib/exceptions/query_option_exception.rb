class TabularOperationException < StandardError
  def initialize(option, key)
    super("Missing #{key} in #{option}")
  end
end