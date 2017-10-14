#!/usr/bin/ruby
require 'libmsg'
require 'thread'

module CIAX
  # Extended Thread class
  module Threadx
    Threads = ThreadGroup.new
    Thread.current[:name] = 'Main'
    Thread.current[:layer] = 'top'
    Thread.current[:id] = File.basename($PROGRAM_NAME)

    module_function

    def list
      Thread.list.map do |t|
        %i(id layer name).map { |id| t[id] }.unshift("[#{t.status}]").join(':') + "\n"
      end.sort.join
    end

    def killall
      Threads.list.each(&:kill)
    end

    # Simple Extention
    class Fork < Thread
      include Msg
      def initialize(tname, layer, id)
        @layer = layer
        @id = id
        th = super { _do_proc(id) { yield } }
        th[:layer] = layer
        th[:name] = tname
        th[:id] = id
        Threads.add(th)
      end

      private

      def _do_proc(_id)
        Thread.pass
        verbose { 'Initiate Thread' }
        yield
      rescue Exception
        errmsg
      end
    end

    # Thread with Loop
    class Loop < Fork
      def initialize(tname, layer, id)
        super do
          loop do
            yield
            verbose { "Next for #{Thread.current[:name]}" }
          end
        end
      end
    end

    # Queue Thread with Loop
    class QueLoop < Fork
      def initialize(tname, layer, id)
        @in = Queue.new
        @out = Queue.new
        super { loop { yield @in, @out } }
      end

      def push(str) # returns self
        warning("Thread [#{self[:name]}] is not running") unless alive?
        @in.push(str)
        self
      end

      def shift
        @out.shift
      end

      def clear
        @in.clear
        @out.clear
        self
      end
    end
  end
end
