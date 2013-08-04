#!/usr/bin/ruby
require 'libmsg'
module CIAX
  class Procs < Hash
    def initialize
      super
      self.default=proc{}
    end
  end

  class ProcAry < Array
    def [](id)
      each{|prcs|
        return prcs[id] if prcs.key?(id)
      }
      Proc.new
    end
  end
end
