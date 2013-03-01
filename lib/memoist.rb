# require 'active_support/core_ext/kernel/singleton_class'
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
        instance_variable_get(ivar).clear if instance_variable_defined?(ivar)
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

      class_eval do
        include InstanceMethods

        if method_defined?(unmemoized_method)
          raise "Already memoized #{method_name}"
        end
        alias_method unmemoized_method, method_name

        if instance_method(method_name).arity == 0
          module_eval <<-EOS, __FILE__, __LINE__ + 1
            def #{method_name}(reload = false)                                     #   def mime_type(reload = false)
              if reload || !defined?(#{memoized_ivar}) || #{memoized_ivar}.empty?  #     if reload || !defined?(@_memoized_mime_type) || @_memoized_mime_type.empty?
                #{memoized_ivar} = [#{unmemoized_method}]                          #       @_memoized_mime_type = [_unmemoized_mime_type]
              end                                                                  #     end
              #{memoized_ivar}[0]                                                  #     @_memoized_mime_type[0]
            end                                                                    #   end
          EOS
        else
          module_eval <<-EOS, __FILE__, __LINE__ + 1
            def #{method_name}(*args)                                              #   def mime_type(*args)
              #{memoized_ivar} ||= {} unless frozen?                               #     @_memoized_mime_type ||= {} unless frozen?
              args_length = method(:#{unmemoized_method}).arity                    #     args_length = method(:_unmemoized_mime_type).arity
              if args.length == args_length + 1 &&                                 #     if args.length == args_length + 1 &&
                (args.last == true || args.last == :reload)                        #       (args.last == true || args.last == :reload)
                reload = args.pop                                                  #       reload = args.pop
              end                                                                  #     end
                                                                                   #
              if defined?(#{memoized_ivar}) && #{memoized_ivar}                    #     if defined?(@_memoized_mime_type) && @_memoized_mime_type
                if !reload && #{memoized_ivar}.has_key?(args)                      #       if !reload && @_memoized_mime_type.has_key?(args)
                  #{memoized_ivar}[args]                                           #         @_memoized_mime_type[args]
                elsif #{memoized_ivar}                                             #       elsif @_memoized_mime_type
                  #{memoized_ivar}[args] = #{unmemoized_method}(*args)             #         @_memoized_mime_type[args] = _unmemoized_mime_type(*args)
                end                                                                #       end
              else                                                                 #     else
                #{unmemoized_method}(*args)                                        #       _unmemoized_mime_type(*args)
              end                                                                  #     end
            end                                                                    #   end
          EOS
        end

        if private_method_defined?(unmemoized_method)
          private method_name
        elsif protected_method_defined?(unmemoized_method)
          protected method_name
        end
      end
    end
  end
end
