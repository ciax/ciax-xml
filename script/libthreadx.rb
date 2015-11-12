#!/usr/bin/ruby
require 'libmsg'
require 'thread'

module CIAX
  class Threadx < Thread
    NS_COLOR = 4
    include Msg
    def initialize(name, color = 4)
      Thread.abort_on_exception = true
      th = super do
        Thread.pass
        yield
      end
      th[:name] = name
      th[:color] = color
    end

    def self.list
      Thread.list.map { |t| t[:name] }
    end
  end

  class ThreadLoop < Threadx
    def initialize(name, color = 4)
      super do
        loop do
          yield
          verbose { "Next for #{Thread.current[:name]}" }
        end
      end
    end
  end
end
