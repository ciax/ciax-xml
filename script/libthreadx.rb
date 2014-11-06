#!/usr/bin/ruby
require "libmsg"
require "thread"

module CIAX
  class Threadx < Thread
    include Msg
    def initialize(name,color=4)
      th=super{
        Thread.pass
        yield
      }
      th[:name]=name
      th[:color]=color
    end
  end

  class ThreadLoop < Threadx
    def initialize(name,color=4)
      super{
        loop{
          yield
          verbose("Threadx","Next for #{Thread.current[:name]}")
        }
      }
    end
  end
end
