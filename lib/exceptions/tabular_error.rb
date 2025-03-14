class TabularError < StandardError
  def initialize(msg)
    super("TabularDB: #{msg}")
  end
end