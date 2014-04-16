# A subclass in its own file that we can load repeatedly
class DummySubclass < Dummy
  extend Memoist

  def sub_increment
    @sub_value ||= 0
    @sub_value += 1
  end

  memoize :sub_increment

end
