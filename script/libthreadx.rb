#!/usr/bin/ruby
require "thread"
module CIAX
  class Threadx < Thread
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
        }
      }
    end
  end
end
