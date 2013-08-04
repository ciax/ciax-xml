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
    def initialize
      @procary=[Procs.new]
    end

    def add
      prc=Procs.new
      @procary.unshift prc
      prc
    end

    def [](id)
      each{|prcs|
        return prcs[id] if prcs.key?(id)
      }
      Proc.new
    end
  end
end
