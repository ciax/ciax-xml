#!/usr/bin/env ruby
require 'libhashx'
module CIAX
  # Proc Array
  class ProcArray < Arrayx
    def initialize(obj)
      @obj = obj
      super()
    end

    def call
      compact.each { |p| p.call(self) }
      self
    end

    def view
      compact.map do |p|
        path, line = p.source_location
        /lib(.+).rb/ =~ path
        "#{Regexp.last_match(1)}:#{line}"
      end
    end

    # Append proc after name proc
    def append(name, &prc)
      idx = view.index { |s| /#{name}/ =~ s }
      insert(idx + 1, prc)
    end

    # Set time_upd with lower layer time
    def time2cmt(stat = nil)
      unshift(
        stat ? proc { time_upd(stat[:time]) } : proc { time_upd }
      )
      self
    end
  end
end
