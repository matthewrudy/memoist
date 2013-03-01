# require 'active_support/core_ext/kernel/singleton_class'
require 'memoist/core_ext/singleton_class'

module Memoist

  def self.memoized_ivar_for(method_name, identifier=nil)
    ["@_memoized", identifier, escape_punctuation(method_name.to_s)].compact.join("_")
  end

  def self.unmemoized_method_for(method_name, identifier=nil)
    ["_unmemoized", identifier, method_name].compact.join("_").to_sym
  end

  def self.escape_punctuation(string)
    string.sub(/\?\Z/, '_query').sub(/!\Z/, '_bang')
  end

  module InstanceMethods
    def self.included(base)
      base.class_eval do
        unless base.method_defined?(:freeze_without_memoizable)
          alias_method :freeze_without_memoizable, :freeze
          alias_method :freeze, :freeze_with_memoizable
        end
      end
    end

    def freeze_with_memoizable
      memoize_all unless frozen?
      freeze_without_memoizable
    end

    def memoize_all
      prime_cache
    end

    def unmemoize_all
      flush_cache
    end

    def prime_cache(*syms)
      if syms.empty?
        syms = methods.collect do |m|
          m[12..-1] if m.to_s.start_with?("_unmemoized_")
        end.compact
      end

      syms.each do |sym|
        m = method(:"_unmemoized_#{sym}") rescue next
        if m.arity == 0
          __send__(sym)
        else
          ivar = Memoist.memoized_ivar_for(sym)
          instance_variable_set(ivar, {})
        end
      end
    end

    def flush_cache(*syms)
      if syms.empty?
        syms = (methods + private_methods + protected_methods).collect do |m|
          m[12..-1] if m.to_s.start_with?("_unmemoized_")
        end.compact
      end

      syms.each do |sym|
        ivar = Memoist.memoized_ivar_for(sym)
        instance_variable_get(ivar).clear if instance_variable_defined?(ivar)
      end
    end
  end

  def memoize(*symbols)
    if symbols.last.is_a?(Hash)
      identifier = symbols.pop[:identifier]
    end

    symbols.each do |symbol|
      original_method = Memoist.unmemoized_method_for(symbol, identifier)
      memoized_ivar = Memoist.memoized_ivar_for(symbol, identifier)

      class_eval do
        include InstanceMethods

        if method_defined?(original_method)
          raise "Already memoized #{symbol}"
        end
        alias_method original_method, symbol

        if instance_method(symbol).arity == 0
          module_eval <<-EOS, __FILE__, __LINE__ + 1
            def #{symbol}(reload = false)                                          #   def mime_type(reload = false)
              if reload || !defined?(#{memoized_ivar}) || #{memoized_ivar}.empty?  #     if reload || !defined?(@_memoized_mime_type) || @_memoized_mime_type.empty?
                #{memoized_ivar} = [#{original_method}]                            #       @_memoized_mime_type = [_unmemoized_mime_type]
              end                                                                  #     end
              #{memoized_ivar}[0]                                                  #     @_memoized_mime_type[0]
            end                                                                    #   end
          EOS
        else
          module_eval <<-EOS, __FILE__, __LINE__ + 1
            def #{symbol}(*args)                                                   #   def mime_type(*args)
              #{memoized_ivar} ||= {} unless frozen?                               #     @_memoized_mime_type ||= {} unless frozen?
              args_length = method(:#{original_method}).arity                      #     args_length = method(:_unmemoized_mime_type).arity
              if args.length == args_length + 1 &&                                 #     if args.length == args_length + 1 &&
                (args.last == true || args.last == :reload)                        #       (args.last == true || args.last == :reload)
                reload = args.pop                                                  #       reload = args.pop
              end                                                                  #     end
                                                                                   #
              if defined?(#{memoized_ivar}) && #{memoized_ivar}                    #     if defined?(@_memoized_mime_type) && @_memoized_mime_type
                if !reload && #{memoized_ivar}.has_key?(args)                      #       if !reload && @_memoized_mime_type.has_key?(args)
                  #{memoized_ivar}[args]                                           #         @_memoized_mime_type[args]
                elsif #{memoized_ivar}                                             #       elsif @_memoized_mime_type
                  #{memoized_ivar}[args] = #{original_method}(*args)               #         @_memoized_mime_type[args] = _unmemoized_mime_type(*args)
                end                                                                #       end
              else                                                                 #     else
                #{original_method}(*args)                                          #       _unmemoized_mime_type(*args)
              end                                                                  #     end
            end                                                                    #   end
          EOS
        end

        if private_method_defined?(original_method)
          private symbol
        elsif protected_method_defined?(original_method)
          protected symbol
        end
      end
    end
  end
end
