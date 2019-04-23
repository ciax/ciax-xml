#!/usr/bin/env ruby
require 'libstruct'
module CIAX
  module View
    # Show branch (omit lower tree of Hash/Array with sym key)
    module Path
      include Msg
      def path(ary = [])
        enum = ary.inject(self) do |prev, a|
          ___values_by_type(prev, a)
        end || Msg.args_err('No such key')
        ___view_branch(enum.dup)
      end

      private

      def ___values_by_type(var, idx)
        return var.instance_variable_get(idx) if /@/ =~ idx
        case var
        when Array
          var[idx.to_i]
        when Hash
          var[idx.to_sym] || var[idx.to_s]
        end
      end

      def ___view_branch(var)
        ___view_hash(var)
        var.instance_variables.each do |n|
          v = var.instance_variable_get(n)
          var.instance_variable_set(n, v.class.to_s) if v.is_a?(Enumerable)
        end
        Struct.new(var).to_s
      end

      def ___view_hash(var)
        return unless var.is_a? Hash
        var.each do |k, v|
          var[k] = v.class.to_s if v.is_a?(Enumerable) || !v.is_a?(Comparable)
        end
      end
    end
  end
end
