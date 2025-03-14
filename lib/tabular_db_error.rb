class TabularDBError < StandardError
  def initialize(msg)
    super("TabularDB: #{msg}")
  end
end