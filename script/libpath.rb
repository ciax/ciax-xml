#!/usr/bin/ruby
require 'libstruct'
module CIAX
  # Show branch (omit lower tree of Hash/Array with sym key)
  module ViewPath
    include ViewStruct

    def path(ary = [])
      enum = ary.inject(self) do |prev, a|
        _values_by_type(prev, a)
      end || Msg.give_up('No such key')
      _view_branch(enum.dup.extend(ViewStruct))
    end

    private

    def _values_by_type(var, idx)
      return var.instance_variable_get(idx) if /@/ =~ idx
      case var
      when Array
        var[idx.to_i]
      when Hash
        var[idx.to_sym] || var[idx.to_s]
      end
    end

    def _view_branch(var)
      _view_hash(var)
      var.instance_variables.each do |n|
        v = var.instance_variable_get(n)
        var.instance_variable_set(n, v.class.to_s) if v.is_a?(Enumerable)
      end
      var.view_struct(true, true)
    end

    def _view_hash(var)
      return unless var.is_a? Hash
      var.each do |k, v|
        var[k] = v.class.to_s if v.is_a?(Enumerable)
      end
    end
  end
end
