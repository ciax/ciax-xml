#!/usr/bin/ruby
require 'libcmdpar'

module CIAX
  # Macro Layer
  module Mcr
    # Macro Number Validation
    class Parameter < CmdBase::Parameter
      # @list is RecList.list.keys
      attr_reader :list, :current_idx

      def initialize(list = [])
        hash = { type: 'str', list: (@list = list) }
        super(hash)
        @current_idx = 0
      end

      # select id by index number (1~max)
      #  return id otherwise nil
      def sel(idx)
        @current_idx = limit(0, @list.size, idx.to_i)
        if @current_idx < 1
          delete(:default)
        else
          self[:default] = @list[@current_idx - 1]
          verbose { "Change default to #{self[:default].inspect}" }
        end
        self
      end

      def sel_last
        sel(@list.size)
      end

      # For macro variable param (sid list)
      # replace (default will be last sid)
      def flush(other)
        @list.replace other
        sel_last
      end

      # push to list (default will be incresed)
      def push(id) # returns self
        return self if @list.include?(id)
        @list << id
        sel_last
      end

      def current_rid
        self[:default] if key?(:default)
      end
    end
  end
end
