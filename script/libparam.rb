#!/usr/bin/ruby
require 'libenumx'

module CIAX
  class Parameter < Hashx
    def initialize(type = nil, default = nil)
      super(type: type, list: [], default: default)
      unless type
        self[:type] = 'reg'
        self[:list] << '.'
      end
    end

    #replace (default is decresed)
    def flush(other);end
    #add to list (default is incresed)
    def add(e);end
    #set default
    def set_def(id);end
  end
end
