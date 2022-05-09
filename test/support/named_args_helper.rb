# frozen_string_literal: true

require 'memoist'

class NamedArgsHelper
  extend Memoist

  def initialize(a1:)
    @a1 = a1
  end

  def calc_with_named_args(a2:, a3: nil)
    create_object(a1: a1, a2: a2, a3: a3)
  end
  memoize :calc_with_named_args

  def calc_with_positioned_args(a2, a3 = nil)
    create_object(a1: a1, a2: a2, a3: a3)
  end
  memoize :calc_with_positioned_args

  def calc_with_mixed_args(a2, a3: nil)
    create_object(a1: a1, a2: a2, a3: a3)
  end
  memoize :calc_with_mixed_args

  private

  attr_reader :a1

  def create_object(**named_args)
    OpenStruct.new(**named_args)
  end
end
