#!/usr/bin/ruby
require 'libenumx'

module CIAX
  class Parameter < Hashx
    def initialize(type = nil)
      super(type: type, list: [], default: nil)
      unless type
        self[:type] = 'reg'
        self[:list] << '.'
      end
    end
  end
end
