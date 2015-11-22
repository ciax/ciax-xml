#!/usr/bin/ruby
require 'libstruct'
module CIAX
  # Show branch (omit lower tree of Hash/Array with sym key)
  module ViewPath
    include ViewStruct

    def path(ary = [])
      enum = ary.inject(self) do|prev, a|
        if /@/ =~ a
          prev.instance_variable_get(a)
        else
          case prev
          when Array
            prev[a.to_i]
          when Hash
            prev[a.to_sym] || prev[a.to_s]
          end
        end
      end || Msg.give_up('No such key')
      branch = enum.dup.extend(ViewStruct)
      if branch.is_a? Hash
        branch.each do|k, v|
          branch[k] = v.class.to_s if v.is_a?(Enumerable)
        end
      end
      branch.instance_variables.each do|n|
        v = branch.instance_variable_get(n)
        branch.instance_variable_set(n, v.class.to_s) if v.is_a?(Enumerable)
      end
      branch.view_struct(true, true)
    end
  end
end
