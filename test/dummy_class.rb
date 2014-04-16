# A class in its own file that we can load repeatedly
class Dummy
  extend Memoist

  def increment
    @value ||= 0
    @value += 1
  end

  memoize :increment

end
