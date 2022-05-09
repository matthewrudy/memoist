require 'pry-rails'
require 'test_helper'
require_relative '../support/named_args_helper'

class MemoistNamedArgsTest < Minitest::Test
  def test_named_args_class_initialization
    instance1 = ::NamedArgsHelper.new(a1: 11)
    instance2 = ::NamedArgsHelper.new(a1: 11)

    refute_same instance1, instance2
  end

  def test_memoized_object_is_properly_caching_with_named_args
    instance = ::NamedArgsHelper.new(a1: 11)
    result1 = instance.calc_with_named_args(a2: 12, a3: 13)
    _result2 = instance.calc_with_named_args(a2: 13, a3: 13)
    result3 = instance.calc_with_named_args(a2: 12, a3: 13)

    assert_same result1, result3
  end

  def test_memoized_object_is_properly_caching_with_positioned_args
    instance = ::NamedArgsHelper.new(a1: 11)
    result1 = instance.calc_with_positioned_args(12, 13)
    _result2 = instance.calc_with_positioned_args(13, 13)
    result3 = instance.calc_with_positioned_args(12, 13)

    assert_same result1, result3
  end

  def test_memoized_object_is_properly_caching_with_mixed_args
    instance = ::NamedArgsHelper.new(a1: 11)
    result1 = instance.calc_with_mixed_args(12, a3: 13)
    _result2 = instance.calc_with_mixed_args(13, a3: 13)
    result3 = instance.calc_with_mixed_args(12, a3: 13)

    assert_same result1, result3
  end
end
