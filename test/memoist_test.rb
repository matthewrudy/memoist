require 'test_helper'
require 'memoist'

class MemoistTest < Minitest::Test

  class CallCounter

    def initialize
      @calls = {}
    end

    def call(method_name)
      @calls[method_name] ||= 0
      @calls[method_name] += 1
    end

    def count(method_name)
      @calls[method_name] ||= 0
    end

  end

  class Person
    extend Memoist

    def initialize
      @counter = CallCounter.new
    end

    def name_calls
      @counter.count(:name)
    end

    def student_name_calls
      @counter.count(:student_name)
    end

    def name_query_calls
      @counter.count(:name?)
    end

    def is_developer_calls
      @counter.count(:is_developer?)
    end

    def age_calls
      @counter.count(:age)
    end

    def name
      @counter.call(:name)
      "Josh"
    end

    def name?
      @counter.call(:name?)
      true
    end
    memoize :name?

    def update(name)
      "Joshua"
    end
    memoize :update

    def age
      @counter.call(:age)
      nil
    end

    memoize :name, :age

    def sleep(hours = 8)
      @counter.call(:sleep)
      hours
    end
    memoize :sleep

    def sleep_calls
      @counter.count(:sleep)
    end

    def update_attributes(options = {})
      @counter.call(:update_attributes)
      true
    end
    memoize :update_attributes

    def update_attributes_calls
      @counter.count(:update_attributes)
    end

    protected

    def memoize_protected_test
      'protected'
    end
    memoize :memoize_protected_test

    private

    def is_developer?
      @counter.call(:is_developer?)
      "Yes"
    end
    memoize :is_developer?
  end

  class Student < Person
    def name
      @counter.call(:student_name)
      "Student #{super}"
    end
    memoize :name, :identifier => :student
  end

  class Teacher < Person
    def seniority
      "very_senior"
    end
    memoize :seniority
  end

  class Company
    attr_reader :name_calls
    def initialize
      @name_calls = 0
    end

    def name
      @name_calls += 1
      "37signals"
    end
  end

  module Rates
    extend Memoist

    attr_reader :sales_tax_calls
    def sales_tax(price)
      @sales_tax_calls ||= 0
      @sales_tax_calls += 1
      price * 0.1025
    end
    memoize :sales_tax
  end

  class Calculator
    extend Memoist
    include Rates

    attr_reader :fib_calls
    def initialize
      @fib_calls = 0
    end

    def fib(n)
      @fib_calls += 1

      if n == 0 || n == 1
        n
      else
        fib(n - 1) + fib(n - 2)
      end
    end
    memoize :fib

    def add_or_subtract(i, j, add)
      if add
        i + j
      else
        i - j
      end
    end
    memoize :add_or_subtract

    def counter
      @count ||= 0
      @count += 1
    end
    memoize :counter
  end

  def setup
    @person = Person.new
    @calculator = Calculator.new
  end

  def test_memoization
    assert_equal "Josh", @person.name
    assert_equal 1, @person.name_calls

    3.times { assert_equal "Josh", @person.name }
    assert_equal 1, @person.name_calls
  end

  def test_memoize_with_optional_arguments
    assert_equal 4, @person.sleep(4)
    assert_equal 1, @person.sleep_calls

    3.times { assert_equal 4, @person.sleep(4) }
    assert_equal 1, @person.sleep_calls

    3.times { assert_equal 4, @person.sleep(4, :reload) }
    assert_equal 4, @person.sleep_calls
  end

  def test_memoize_with_options_hash
    assert_equal true, @person.update_attributes(:age => 21, :name => 'James')
    assert_equal 1, @person.update_attributes_calls

    3.times { assert_equal true, @person.update_attributes(:age => 21, :name => 'James') }
    assert_equal 1, @person.update_attributes_calls

    3.times { assert_equal true, @person.update_attributes({:age => 21, :name => 'James'}, :reload) }
    assert_equal 4, @person.update_attributes_calls
  end

  def test_memoization_with_punctuation
    assert_equal true, @person.name?

    @person.memoize_all
    @person.unmemoize_all
  end

  def test_memoization_flush_with_punctuation
    assert_equal true, @person.name?
    @person.flush_cache(:name?)
    3.times { assert_equal true, @person.name? }
    assert_equal 2, @person.name_query_calls
  end

  def test_memoization_with_nil_value
    assert_equal nil, @person.age
    assert_equal 1, @person.age_calls

    3.times { assert_equal nil, @person.age }
    assert_equal 1, @person.age_calls
  end

  def test_reloadable
    assert_equal 1, @calculator.counter
    assert_equal 2, @calculator.counter(:reload)
    assert_equal 2, @calculator.counter
    assert_equal 3, @calculator.counter(true)
    assert_equal 3, @calculator.counter
  end

  def test_flush_cache
    assert_equal 1, @calculator.counter

    assert @calculator.instance_variable_get(:@_memoized_counter)
    @calculator.flush_cache(:counter)
    assert_nil @calculator.instance_variable_get(:@_memoized_counter)
    assert !@calculator.instance_variable_defined?(:@_memoized_counter)

    assert_equal 2, @calculator.counter
  end

  def test_unmemoize_all
    assert_equal 1, @calculator.counter

    assert @calculator.instance_variable_get(:@_memoized_counter)
    @calculator.unmemoize_all
    assert_nil @calculator.instance_variable_get(:@_memoized_counter)
    assert !@calculator.instance_variable_defined?(:@_memoized_counter)

    assert_equal 2, @calculator.counter
  end

  def test_all_memoized_structs
    # Person             memoize :age, :is_developer?, :memoize_protected_test, :name, :name?, :sleep, :update, :update_attributes
    # Student < Person   memoize :name, :identifier => :student
    # Teacher < Person   memoize :seniority

    expected = %w(age is_developer? memoize_protected_test name name? sleep update update_attributes)
    structs = Person.all_memoized_structs
    assert_equal expected, structs.collect(&:memoized_method).collect(&:to_s).sort
    assert_equal "@_memoized_name", structs.detect {|s| s.memoized_method == :name }.ivar

    # Same expected methods
    structs = Student.all_memoized_structs
    assert_equal expected, structs.collect(&:memoized_method).collect(&:to_s).sort
    assert_equal "@_memoized_student_name", structs.detect {|s| s.memoized_method == :name }.ivar

    expected = (expected << "seniority").sort
    structs = Teacher.all_memoized_structs
    assert_equal expected, structs.collect(&:memoized_method).collect(&:to_s).sort
    assert_equal "@_memoized_name", structs.detect {|s| s.memoized_method == :name }.ivar
  end

  def test_unmemoize_all_subclasses
    # Person             memoize :age, :is_developer?, :memoize_protected_test, :name, :name?, :sleep, :update, :update_attributes
    # Student < Person   memoize :name, :identifier => :student
    # Teacher < Person   memoize :seniority

    teacher = Teacher.new
    assert_equal "Josh", teacher.name
    assert_equal "Josh", teacher.instance_variable_get(:@_memoized_name)
    assert_equal "very_senior", teacher.seniority
    assert_equal "very_senior", teacher.instance_variable_get(:@_memoized_seniority)

    teacher.unmemoize_all
    assert_nil teacher.instance_variable_get(:@_memoized_name)
    assert_nil teacher.instance_variable_get(:@_memoized_seniority)

    student = Student.new
    assert_equal "Student Josh", student.name
    assert_equal "Student Josh", student.instance_variable_get(:@_memoized_student_name)
    assert_nil student.instance_variable_get(:@_memoized_seniority)

    student.unmemoize_all
    assert_nil student.instance_variable_get(:@_memoized_student_name)
  end

  def test_memoize_all
    @calculator.memoize_all
    assert @calculator.instance_variable_defined?(:@_memoized_counter)
  end

  def test_memoize_all_subclasses
    # Person             memoize :age, :is_developer?, :memoize_protected_test, :name, :name?, :sleep, :update, :update_attributes
    # Student < Person   memoize :name, :identifier => :student
    # Teacher < Person   memoize :seniority

    teacher = Teacher.new
    teacher.memoize_all

    assert_equal "very_senior", teacher.instance_variable_get(:@_memoized_seniority)
    assert_equal "Josh", teacher.instance_variable_get(:@_memoized_name)

    student = Student.new
    student.memoize_all

    assert_equal "Student Josh", student.instance_variable_get(:@_memoized_student_name)
    assert_equal "Student Josh", student.name
    assert_nil student.instance_variable_get(:@_memoized_seniority)
  end

  def test_memoization_cache_is_different_for_each_instance
    assert_equal 1, @calculator.counter
    assert_equal 2, @calculator.counter(:reload)
    assert_equal 1, Calculator.new.counter
  end

  def test_memoized_is_not_affected_by_freeze
    @person.freeze
    assert_equal "Josh", @person.name
    assert_equal "Joshua", @person.update("Joshua")
  end

  def test_memoization_with_args
    assert_equal 55, @calculator.fib(10)
    assert_equal 11, @calculator.fib_calls
  end

  def test_reloadable_with_args
    assert_equal 55, @calculator.fib(10)
    assert_equal 11, @calculator.fib_calls
    assert_equal 55, @calculator.fib(10, :reload)
    assert_equal 12, @calculator.fib_calls
    assert_equal 55, @calculator.fib(10, true)
    assert_equal 13, @calculator.fib_calls
  end

  def test_memoization_with_boolean_arg
    assert_equal 4, @calculator.add_or_subtract(2, 2, true)
    assert_equal 2, @calculator.add_or_subtract(4, 2, false)
  end

  def test_object_memoization
    [Company.new, Company.new, Company.new].each do |company|
      company.extend Memoist
      company.memoize :name

      assert_equal "37signals", company.name
      assert_equal 1, company.name_calls
      assert_equal "37signals", company.name
      assert_equal 1, company.name_calls
    end
  end

  def test_memoized_module_methods
    assert_equal 1.025, @calculator.sales_tax(10)
    assert_equal 1, @calculator.sales_tax_calls
    assert_equal 1.025, @calculator.sales_tax(10)
    assert_equal 1, @calculator.sales_tax_calls
    assert_equal 2.5625, @calculator.sales_tax(25)
    assert_equal 2, @calculator.sales_tax_calls
  end

  def test_object_memoized_module_methods
    company = Company.new
    company.extend(Rates)

    assert_equal 1.025, company.sales_tax(10)
    assert_equal 1, company.sales_tax_calls
    assert_equal 1.025, company.sales_tax(10)
    assert_equal 1, company.sales_tax_calls
    assert_equal 2.5625, company.sales_tax(25)
    assert_equal 2, company.sales_tax_calls
  end

  def test_double_memoization_with_identifier
    # Person             memoize :age, :is_developer?, :memoize_protected_test, :name, :name?, :sleep, :update, :update_attributes
    # Student < Person   memoize :name, :identifier => :student
    # Teacher < Person   memoize :seniority

    Person.memoize :name, :identifier => :again
    p = Person.new
    assert_equal "Josh", p.name
    assert p.instance_variable_get(:@_memoized_again_name)

    # HACK: tl;dr: Don't memoize classes in test that are used elsewhere.
    # Calling Person.memoize :name, :identifier => :again pollutes Person
    # and descendents since we cache the memoized method structures.
    # This populates those structs, verifies Person is polluted, resets the
    # structs, cleans up cached memoized_methods
    Student.all_memoized_structs
    Person.all_memoized_structs
    Teacher.all_memoized_structs
    assert Person.memoized_methods.any? { |m| m.ivar == "@_memoized_again_name" }

    [Student, Teacher, Person].each { |obj| obj.clear_structs }
    assert Person.memoized_methods.reject!      { |m| m.ivar == "@_memoized_again_name" }
    assert_nil Student.memoized_methods.reject! { |m| m.ivar == "@_memoized_again_name" }
    assert_nil Teacher.memoized_methods.reject! { |m| m.ivar == "@_memoized_again_name" }
  end

  def test_memoization_with_a_subclass
    student = Student.new
    student.name
    student.name
    assert_equal 1, student.student_name_calls
    assert_equal 1, student.name_calls
  end

  def test_memoization_is_chainable
    klass = Class.new do
      def foo; "bar"; end
    end
    klass.extend Memoist
    chainable = klass.memoize :foo
    assert_equal :foo, chainable
  end

  def test_protected_method_memoization
    person = Person.new

    assert_raises(NoMethodError) { person.memoize_protected_test }
    assert_equal "protected", person.send(:memoize_protected_test)
  end

  def test_private_method_memoization
    person = Person.new

    assert_raises(NoMethodError) { person.is_developer? }
    assert_equal "Yes", person.send(:is_developer?)
    assert_equal 1, person.is_developer_calls
    assert_equal "Yes", person.send(:is_developer?)
    assert_equal 1, person.is_developer_calls
  end

  def test_blocks_supported
    person = Person.new

    assert_raises(Memoist::BlocksNotSupported) { person.name { :block } }
    assert_raises(Memoist::BlocksNotSupported) { person.update('smth') { :block } }
  end

  def test_block_contains_proper_caller
    person = Person.new

    begin
      person.name { :block }
    rescue Memoist::BlocksNotSupported => e
      assert(e.message =~ /memoist_test.rb:\d+/, "message should contain caller of memoize")
    end
  end
end
