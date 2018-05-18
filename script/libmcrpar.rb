#!/usr/bin/ruby
require 'libcmdpar'

module CIAX
  # Macro Layer
  module Mcr
    # Macro Number Validation
    class Parameter < CmdBase::Parameter
      # @list is most recent record ids
      attr_reader :list

      def initialize(hash = {})
        hash = { type: 'str', list: (@list = []) }
        super(hash)
      end

      # select id by index number (1~max)
      #  return id otherwise nil
      def sel(idx)
        if idx < 1
          delete(:default)
        else
          idx = @list.size if idx > @list.size
          self[:default] = @list[idx - 1]
          verbose { "Change default to #{self[:default].inspect}" }
        end
        self
      end

      # For macro variable param (sid list)
      # replace (default will be decresed)
      def flush(other)
        @list.replace other
        if key?(:default) && !@list.include?(self[:default])
          self[:default] = @list.last
        end
        self
      end

      # push to list (default will be incresed)
      def push(id) # returns self
        return self if @list.include?(id)
        @list << id
        self[:default] = id
        self
      end

      def current_idx
        @list.index(self[:default]) if key?(:default)
      end

      def current_rid
        self[:default] if key?(:default)
      end
    end
  end
end
