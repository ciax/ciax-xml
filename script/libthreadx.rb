#!/usr/bin/ruby
require "libmsg"
require "thread"

module CIAX
  class Threadx < Thread
    include Msg
    def initialize(name,color=4)
      Thread.abort_on_exception=true
      th=super{
        Thread.pass
        yield
      }
      th[:name]=name
      th[:color]=color
    end

    def self.list
      Thread.list.map{|t| t['name']}
    end
  end

  class ThreadLoop < Threadx
    def initialize(name,color=4)
      super{
        loop{
          yield
          verbose("Next for #{Thread.current[:name]}")
        }
      }
    end
  end
end
