#!/usr/bin/ruby
require 'libenumx'

module CIAX
  # Macro Layer
  module Mcr
    # Macro Number Validation
    class Parameter < Hashx
      # @list is most recent record list
      attr_reader :list

      def initialize(default = nil, lines = 0)
        super(type: 'str', list: [])
        @list = self[:list]
        self[:default] = default if default
      end

      # select id by number (1~max)
      #  return id otherwise nil
      def sel(num = nil)
        num = ___reg_crnt(num)
        self[:default] = num && num > 0 ? @list[num - 1] : nil
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

      def index
        @list.index(self[:default])
      end

      def current
        self[:default]
      end

      private

      # num is regurated within 0 to max
      def ___reg_crnt(num)
        return if !num || num < 0
        num = @list.size if num > @list.size
        num
      end
    end
  end
end
