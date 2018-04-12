#!/usr/bin/ruby
require 'libenumx'

module CIAX
  # Macro Layer
  module Mcr
    # Macro Number Validation
    class Parameter < Hashx
      # @list is most recent record ids
      attr_reader :list

      def initialize(default = nil)
        super(type: 'str', list: (@list = []))
        self[:default] = default if default
      end

      # select id by index number (1~max)
      #  return id otherwise nil
      def sel(idx = nil)
        if !idx || idx < 1
          self[:default] = nil
        else
          idx = @list.size if idx > @list.size
          self[:default] = @list[idx - 1]
        end
      end

      # For macro variable param (sid list)
      # replace (default is decresed)
      def flush(other)
        @list.replace other
        if self[:default] && !@list.include?(self[:default])
          self[:default] = @list.last
        end
        self
      end

      # push to list (default is incresed)
      def push(id) # returns self
        @list << id unless @list.include?(id)
        self[:default] = id
        self
      end

      def current_idx
        @list.index(self[:default])
      end

      def current_rid
        self[:default]
      end
    end
  end
end
