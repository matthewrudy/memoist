# A module in its own file that we can load repeatedly
module DummyModule
  extend Memoist

  def module_increment
    @mod_value ||= 0
    @mod_value += 1
  end

  memoize :module_increment

end
