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

  module Countable
    attr_reader :counter

    def initialize
      @counter = CallCounter.new
    end

    def calls(method_name)
      counter.count(method_name)
    end
  end

  class Person
    extend Memoist
    include Countable

    def name
      counter.call(:name)
      'Josh'
    end

    def name?
      counter.call(:name?)
      true
    end
    memoize :name?

    def update(_name)
      'Joshua'
    end
    memoize :update

    def age
      counter.call(:age)
      nil
    end

    memoize :name, :age

    def age?
      counter.call(:age?)
      true
    end
    memoize 'age?'

    def sleep(hours = 8)
      counter.call(:sleep)
      hours
    end
    memoize :sleep

    def update_attributes(_options = {})
      counter.call(:update_attributes)
      true
    end
    memoize :update_attributes

    def rest(*args)
      counter.call(:rest)

      args.each_with_index.each_with_object({}) do |(arg, i), memo|
        memo[i + 1] = arg
      end
    end
    memoize :rest

    def rest_and_kwargs(*args, **options)
      counter.call(:rest_and_kwargs)

      i = 0

      rest = args.each_with_object({}) do |arg, memo|
        memo[i += 1] = arg
      end

      kwargs = options.each_with_object({}) do |(key, value), memo|
        memo[i += 1] = [key, value]
      end

      { rest: rest, kwargs: kwargs }
    end
    memoize :rest_and_kwargs

    def kwargs(**options)
      counter.call(:kwargs)

      options.each_with_index.each_with_object({}) do |((key, value), i), memo|
        memo[i += 1] = [key, value]
      end
    end
    memoize :kwargs

    protected

    def memoize_protected_test
      'protected'
    end
    memoize :memoize_protected_test

    private

    def is_developer?
      counter.call(:is_developer?)
      'Yes'
    end
    memoize :is_developer?
  end

  class Student < Person
    def name
      counter.call(:student_name)
      "Student #{super}"
    end
    memoize :name, identifier: :student
  end

  class Teacher < Person
    def seniority
      'very_senior'
    end
    memoize :seniority
  end

  class Company
    include Countable

    def name
      counter.call(:name)
      '37signals'
    end
  end

  module Rates
    extend Memoist
    include Countable

    def sales_tax(price)
      counter.call(:sales_tax)
      price * 0.1025
    end
    memoize :sales_tax
  end

  class Calculator
    extend Memoist
    include Countable
    include Rates

    def fib(n)
      counter.call(:fib)

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

    def incrementor
      @incrementor ||= 0
      @incrementor += 1
    end
    memoize :incrementor
  end

  class Book
    extend Memoist
    STATUSES = %w[new used].freeze
    CLASSIFICATION = %w[fiction nonfiction].freeze
    GENRES = %w[humor romance reference sci-fi classic philosophy].freeze

    attr_reader :title, :author
    def initialize(title, author)
      @title = title
      @author = author
    end

    def full_title
      "#{@title} by #{@author}"
    end
    memoize :full_title

    class << self
      extend Memoist

      def all_types
        STATUSES.product(CLASSIFICATION).product(GENRES).collect(&:flatten)
      end
      memoize :all_types
    end
  end

  class Abb
    extend Memoist

    def run(*_args)
      flush_cache if respond_to?(:flush_cache)
      execute
    end

    def execute
      some_method
    end

    def some_method
      # Override this
    end
  end

  class Bbb < Abb
    def some_method
      :foo
    end
    memoize :some_method
  end

  def setup
    @person = Person.new
    @calculator = Calculator.new
    @book = Book.new('My Life', "Brian 'Fudge' Turmuck")
  end

  def test_memoization
    assert_equal 'Josh', @person.name
    assert_equal 1, @person.calls(:name)

    3.times { assert_equal 'Josh', @person.name }
    assert_equal 1, @person.calls(:name)
  end

  def test_memoize_with_optional_arguments
    assert_equal 4, @person.sleep(4)
    assert_equal 1, @person.calls(:sleep)

    3.times { assert_equal 4, @person.sleep(4) }
    assert_equal 1, @person.calls(:sleep)

    3.times { assert_equal 4, @person.sleep(4, :reload) }
    assert_equal 4, @person.calls(:sleep)
  end

  def test_memoize_with_options_hash
    assert_equal true, @person.update_attributes(age: 21, name: 'James')
    assert_equal 1, @person.calls(:update_attributes)

    3.times { assert_equal true, @person.update_attributes(age: 21, name: 'James') }
    assert_equal 1, @person.calls(:update_attributes)

    3.times { assert_equal true, @person.update_attributes({ age: 21, name: 'James' }, :reload) }
    assert_equal 4, @person.calls(:update_attributes)
  end

  def test_memoization_with_punctuation
    assert_equal true, @person.name?

    @person.memoize_all
    @person.unmemoize_all
  end

  def test_memoization_when_memoize_is_called_with_punctuated_string
    assert_equal true, @person.age?

    @person.memoize_all
    @person.unmemoize_all
  end

  def test_memoization_flush_with_punctuation
    assert_equal true, @person.name?
    @person.flush_cache(:name?)
    3.times { assert_equal true, @person.name? }
    assert_equal 2, @person.calls(:name?)
  end

  def test_memoization_with_nil_value
    assert_nil @person.age
    assert_equal 1, @person.calls(:age)

    3.times { assert_nil @person.age }
    assert_equal 1, @person.calls(:age)
  end

  def test_reloadable
    assert_equal 1, @calculator.incrementor
    assert_equal 2, @calculator.incrementor(:reload)
    assert_equal 2, @calculator.incrementor
    assert_equal 3, @calculator.incrementor(true)
    assert_equal 3, @calculator.incrementor
  end

  def test_flush_cache
    assert_equal 1, @calculator.incrementor

    assert @calculator.instance_variable_get(:@_memoized_incrementor)
    @calculator.flush_cache(:incrementor)
    assert_equal false, @calculator.instance_variable_defined?(:@_memoized_incrementor)

    assert_equal 2, @calculator.incrementor
  end

  def test_class_flush_cache
    @book.memoize_all
    assert_equal "My Life by Brian 'Fudge' Turmuck", @book.full_title

    Book.memoize_all
    assert_instance_of Array, Book.instance_variable_get(:@_memoized_all_types)
    Book.flush_cache
    assert_equal false, Book.instance_variable_defined?(:@_memoized_all_types)
  end

  def test_class_flush_cache_preserves_instances
    @book.memoize_all
    Book.memoize_all
    assert_equal "My Life by Brian 'Fudge' Turmuck", @book.full_title

    Book.flush_cache
    assert_equal false, Book.instance_variable_defined?(:@_memoized_all_types)
    assert_equal "My Life by Brian 'Fudge' Turmuck", @book.full_title
  end

  def test_flush_cache_in_child_class
    x = Bbb.new

    # This should not throw error
    x.run
  end

  def test_unmemoize_all
    assert_equal 1, @calculator.incrementor

    assert_equal true, @calculator.instance_variable_defined?(:@_memoized_incrementor)
    assert @calculator.instance_variable_get(:@_memoized_incrementor)
    @calculator.unmemoize_all
    assert_equal false, @calculator.instance_variable_defined?(:@_memoized_incrementor)

    assert_equal 2, @calculator.incrementor
  end

  def test_all_memoized_structs
    # Person             memoize :age, :age?, :is_developer?, :memoize_protected_test, :name, :name?, :sleep, :update, :update_attributes
    # Student < Person   memoize :name, :identifier => :student
    # Teacher < Person   memoize :seniority

    expected = %w[age age? is_developer? memoize_protected_test name name? sleep update update_attributes rest rest_and_kwargs kwargs].sort
    structs = Person.all_memoized_structs
    assert_equal expected, structs.collect(&:memoized_method).collect(&:to_s).sort
    assert_equal '@_memoized_name', structs.detect { |s| s.memoized_method == :name }.ivar

    # Same expected methods
    structs = Student.all_memoized_structs
    assert_equal expected, structs.collect(&:memoized_method).collect(&:to_s).sort
    assert_equal '@_memoized_student_name', structs.detect { |s| s.memoized_method == :name }.ivar

    expected = (expected << 'seniority').sort
    structs = Teacher.all_memoized_structs
    assert_equal expected, structs.collect(&:memoized_method).collect(&:to_s).sort
    assert_equal '@_memoized_name', structs.detect { |s| s.memoized_method == :name }.ivar
  end

  def test_unmemoize_all_subclasses
    # Person             memoize :age, :is_developer?, :memoize_protected_test, :name, :name?, :sleep, :update, :update_attributes
    # Student < Person   memoize :name, :identifier => :student
    # Teacher < Person   memoize :seniority

    teacher = Teacher.new
    assert_equal 'Josh', teacher.name
    assert_equal 'Josh', teacher.instance_variable_get(:@_memoized_name)
    assert_equal 'very_senior', teacher.seniority
    assert_equal 'very_senior', teacher.instance_variable_get(:@_memoized_seniority)

    teacher.unmemoize_all
    assert_equal false, teacher.instance_variable_defined?(:@_memoized_name)
    assert_equal false, teacher.instance_variable_defined?(:@_memoized_seniority)

    student = Student.new
    assert_equal 'Student Josh', student.name
    assert_equal 'Student Josh', student.instance_variable_get(:@_memoized_student_name)
    assert_equal false, student.instance_variable_defined?(:@_memoized_seniority)

    student.unmemoize_all
    assert_equal false, @calculator.instance_variable_defined?(:@_memoized_student_name)
  end

  def test_memoize_all
    @calculator.memoize_all
    assert_equal true, @calculator.instance_variable_defined?(:@_memoized_incrementor)
  end

  def test_memoize_all_subclasses
    # Person             memoize :age, :is_developer?, :memoize_protected_test, :name, :name?, :sleep, :update, :update_attributes
    # Student < Person   memoize :name, :identifier => :student
    # Teacher < Person   memoize :seniority

    teacher = Teacher.new
    teacher.memoize_all

    assert_equal 'very_senior', teacher.instance_variable_get(:@_memoized_seniority)
    assert_equal 'Josh', teacher.instance_variable_get(:@_memoized_name)

    student = Student.new
    student.memoize_all

    assert_equal 'Student Josh', student.instance_variable_get(:@_memoized_student_name)
    assert_equal 'Student Josh', student.name
    assert_equal false, student.instance_variable_defined?(:@_memoized_seniority)
  end

  def test_memoization_cache_is_different_for_each_instance
    assert_equal 1, @calculator.incrementor
    assert_equal 2, @calculator.incrementor(:reload)
    assert_equal 1, Calculator.new.incrementor
  end

  def test_memoization_class_variables
    @book.memoize_all
    assert_equal "My Life by Brian 'Fudge' Turmuck", @book.instance_variable_get(:@_memoized_full_title)
    assert_equal "My Life by Brian 'Fudge' Turmuck", @book.full_title

    Book.memoize_all
    assert_instance_of Array, Book.instance_variable_get(:@_memoized_all_types)
    assert_equal 24, Book.all_types.count
  end

  def test_memoized_is_not_affected_by_freeze
    @person.freeze
    assert_equal 'Josh', @person.name
    assert_equal 'Joshua', @person.update('Joshua')
  end

  def test_memoization_with_args
    assert_equal 55, @calculator.fib(10)
    assert_equal 11, @calculator.calls(:fib)
  end

  def test_reloadable_with_args
    assert_equal 55, @calculator.fib(10)
    assert_equal 11, @calculator.calls(:fib)
    assert_equal 55, @calculator.fib(10, :reload)
    assert_equal 12, @calculator.calls(:fib)
    assert_equal 55, @calculator.fib(10, true)
    assert_equal 13, @calculator.calls(:fib)
  end

  def test_memoization_with_boolean_arg
    assert_equal 4, @calculator.add_or_subtract(2, 2, true)
    assert_equal 2, @calculator.add_or_subtract(4, 2, false)
  end

  def test_object_memoization
    [Company.new, Company.new, Company.new].each do |company|
      company.extend Memoist
      company.memoize :name

      assert_equal '37signals', company.name
      assert_equal 1, company.calls(:name)
      assert_equal '37signals', company.name
      assert_equal 1, company.calls(:name)
    end
  end

  def test_memoized_module_methods
    assert_equal 1.025, @calculator.sales_tax(10)
    assert_equal 1, @calculator.calls(:sales_tax)
    assert_equal 1.025, @calculator.sales_tax(10)
    assert_equal 1, @calculator.calls(:sales_tax)
    assert_equal 2.5625, @calculator.sales_tax(25)
    assert_equal 2, @calculator.calls(:sales_tax)
  end

  def test_object_memoized_module_methods
    company = Company.new
    company.extend(Rates)

    assert_equal 1.025, company.sales_tax(10)
    assert_equal 1, company.calls(:sales_tax)
    assert_equal 1.025, company.sales_tax(10)
    assert_equal 1, company.calls(:sales_tax)
    assert_equal 2.5625, company.sales_tax(25)
    assert_equal 2, company.calls(:sales_tax)
  end

  def test_double_memoization_with_identifier
    # Person             memoize :age, :is_developer?, :memoize_protected_test, :name, :name?, :sleep, :update, :update_attributes
    # Student < Person   memoize :name, :identifier => :student
    # Teacher < Person   memoize :seniority

    Person.memoize :name, identifier: :again
    p = Person.new
    assert_equal 'Josh', p.name
    assert p.instance_variable_get(:@_memoized_again_name)

    # HACK: tl;dr: Don't memoize classes in test that are used elsewhere.
    # Calling Person.memoize :name, :identifier => :again pollutes Person
    # and descendents since we cache the memoized method structures.
    # This populates those structs, verifies Person is polluted, resets the
    # structs, cleans up cached memoized_methods
    Student.all_memoized_structs
    Person.all_memoized_structs
    Teacher.all_memoized_structs
    assert Person.memoized_methods.any? { |m| m.ivar == '@_memoized_again_name' }

    [Student, Teacher, Person].each(&:clear_structs)
    assert Person.memoized_methods.reject!      { |m| m.ivar == '@_memoized_again_name' }
    assert_nil Student.memoized_methods.reject! { |m| m.ivar == '@_memoized_again_name' }
    assert_nil Teacher.memoized_methods.reject! { |m| m.ivar == '@_memoized_again_name' }
  end

  def test_memoization_with_a_subclass
    student = Student.new
    student.name
    student.name
    assert_equal 1, student.calls(:student_name)
    assert_equal 1, student.calls(:name)
  end

  def test_memoization_is_chainable
    klass = Class.new do
      def foo
        'bar'
      end
    end
    klass.extend Memoist
    chainable = klass.memoize :foo
    assert_equal :foo, chainable
  end

  def test_protected_method_memoization
    person = Person.new

    assert_raises(NoMethodError) { person.memoize_protected_test }
    assert_equal 'protected', person.send(:memoize_protected_test)
  end

  def test_private_method_memoization
    person = Person.new

    assert_raises(NoMethodError) { person.is_developer? }
    assert_equal 'Yes', person.send(:is_developer?)
    assert_equal 1, person.calls(:is_developer?)
    assert_equal 'Yes', person.send(:is_developer?)
    assert_equal 1, person.calls(:is_developer?)
  end

  def test_rest
    person = Person.new

    3.times do
      assert_equal({ 1 => :one, 2 => :two, 3 => :three }, person.rest(:one, :two, :three))
    end

    assert_equal 1, person.calls(:rest)
  end

  def test_rest_and_kwargs
    person = Person.new

    3.times do
      assert_equal({
        rest: {
          1 => :one,
          2 => :two,
          3 => :three
        },
        kwargs: {
          4 => [:four, :five],
          5 => [:six, :seven]
        }
      },
      person.rest_and_kwargs(:one, :two, :three, four: :five, six: :seven))
    end

    assert_equal 1, person.calls(:rest_and_kwargs)
  end

  def test_kwargs
    person = Person.new

    3.times do
      assert_equal({
        1 => [:four, :five],
        2 => [:six, :seven]
      },
      person.kwargs(four: :five, six: :seven))
    end

    assert_equal 1, person.calls(:kwargs)
  end
end
