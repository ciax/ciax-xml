#!/usr/bin/ruby
require "libmsg"

module CIAX
  class UpdProc < Array
    include Msg

    def add(&p)
      push(p)
    end

    def upd
      map{|p|
        p.call
      }
    end
  end
end
