require 'memoist/core_ext/singleton_class'

module Memoist

  def self.memoized_ivar_for(method_name, identifier=nil)
    ["@#{memoized_prefix(identifier)}", escape_punctuation(method_name.to_s)].join("_")
  end

  def self.unmemoized_method_for(method_name, identifier=nil)
    [unmemoized_prefix(identifier), method_name].join("_").to_sym
  end

  def self.memoized_prefix(identifier=nil)
    ["_memoized", identifier].compact.join("_")
  end

  def self.unmemoized_prefix(identifier=nil)
    ["_unmemoized", identifier].compact.join("_")
  end

  def self.escape_punctuation(string)
    string.sub(/\?\Z/, '_query').sub(/!\Z/, '_bang')
  end

  def self.memoist_eval(klass, *args, &block)
    if klass.respond_to?(:class_eval)
      klass.class_eval(*args, &block)
    else
      klass.singleton_class.class_eval(*args, &block)
    end
  end

  def self.extract_reload!(method, args)
    if args.length == method.arity.abs + 1 && (args.last == true || args.last == :reload)
      reload = args.pop
    end
    reload
  end

  module InstanceMethods
    def memoize_all
      prime_cache
    end

    def unmemoize_all
      flush_cache
    end

    def prime_cache(*method_names)
      if method_names.empty?
        prefix = Memoist.unmemoized_prefix+"_"
        method_names = methods.collect do |method_name|
          if method_name.to_s.start_with?(prefix)
            method_name[prefix.length..-1]
          end
        end.compact
      end

      method_names.each do |method_name|
        if method(Memoist.unmemoized_method_for(method_name)).arity == 0
          __send__(method_name)
        else
          ivar = Memoist.memoized_ivar_for(method_name)
          instance_variable_set(ivar, {})
        end
      end
    end

    def flush_cache(*method_names)
      if method_names.empty?
        prefix = Memoist.unmemoized_prefix+"_"
        method_names = (methods + private_methods + protected_methods).collect do |method_name|
          if method_name.to_s.start_with?(prefix)
            method_name[prefix.length..-1]
          end
        end.compact
      end

      method_names.each do |method_name|
        ivar = Memoist.memoized_ivar_for(method_name)
        remove_instance_variable(ivar) if instance_variable_defined?(ivar)
      end
    end
  end

  def memoize(*method_names)
    if method_names.last.is_a?(Hash)
      identifier = method_names.pop[:identifier]
    end

    method_names.each do |method_name|
      unmemoized_method = Memoist.unmemoized_method_for(method_name, identifier)
      memoized_ivar = Memoist.memoized_ivar_for(method_name, identifier)

      Memoist.memoist_eval(self) do
        include InstanceMethods

        if method_defined?(unmemoized_method)
          raise AlreadyMemoizedError.new("Already memoized #{method_name}")
        end
        alias_method unmemoized_method, method_name

        if instance_method(method_name).arity == 0

          # define a method like this;

          # def mime_type(reload=true)
          #   skip_cache = reload || !instance_variable_defined?("@_memoized_mime_type")
          #   set_cache = skip_cache && !frozen?
          #
          #   if skip_cache
          #     value = _unmemoized_mime_type
          #   else
          #     value = @_memoized_mime_type
          #   end
          #
          #   if set_cache
          #     @_memoized_mime_type = value
          #   end
          #
          #   value
          # end

          module_eval <<-EOS, __FILE__, __LINE__ + 1
            def #{method_name}(reload = false)
              skip_cache = reload || !instance_variable_defined?("#{memoized_ivar}")
              set_cache = skip_cache && !frozen?

              if skip_cache
                value = #{unmemoized_method}
              else
                value = #{memoized_ivar}
              end

              if set_cache
                #{memoized_ivar} = value
              end

              value
            end
          EOS
        else

          # define a method like this;

          # def mime_type(*args)
          #   reload = Memoist.extract_reload!(method(:_unmemoized_mime_type), args)
          #
          #   skip_cache = reload || !memoized_with_args?(:mime_type, args)
          #   set_cache = skip_cache && !frozen
          #
          #   if skip_cache
          #     value = _unmemoized_mime_type(*args)
          #   else
          #     value = @_memoized_mime_type[args]
          #   end
          #
          #   if set_cache
          #     @_memoized_mime_type ||= {}
          #     @_memoized_mime_type[args] = value
          #   end
          #
          #   value
          # end

          module_eval <<-EOS, __FILE__, __LINE__ + 1
            def #{method_name}(*args)
              reload = Memoist.extract_reload!(method(#{unmemoized_method.inspect}), args)

              skip_cache = reload || !(instance_variable_defined?(#{memoized_ivar.inspect}) && #{memoized_ivar} && #{memoized_ivar}.has_key?(args))
              set_cache = skip_cache && !frozen?

              if skip_cache
                value = #{unmemoized_method}(*args)
              else
                value = #{memoized_ivar}[args]
              end

              if set_cache
                #{memoized_ivar} ||= {}
                #{memoized_ivar}[args] = value
              end

              value
            end
          EOS
        end

        if private_method_defined?(unmemoized_method)
          private method_name
        elsif protected_method_defined?(unmemoized_method)
          protected method_name
        end
      end
    end
    # return a chainable method_name symbol if we can
    method_names.length == 1 ? method_names.first : method_names
  end

  class AlreadyMemoizedError < RuntimeError; end
end
