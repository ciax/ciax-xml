#!/usr/bin/env ruby
require 'libmsg'
require 'thread'

# Add hash manipulate feature to Thread
class Thread
  def update(hash)
    hash.each { |k, v| self[k.to_sym] = v if v }
    self
  end

  def to_hash
    keys.each_with_object({}) { |k, h| h[k] = self[k] }
  end
end

module CIAX
  # Extended Thread class
  module Threadx
    include Msg
    Threads = ThreadGroup.new
    Thread.current.update(name: 'Main', layer: 'top',
                          id: File.basename($PROGRAM_NAME))

    module_function

    # List all threads besides own ThreadGroup member
    def list
      Thread.list.map do |t|
        str = "[#{t.status}]"
        str += %i(id layer name).map { |id| t[id] }.join(':')
        str += "(#{t[:type]})" if t[:type]
        str
      end.sort
    end

    def killall
      Threads.list.each(&:kill)
    end

    # Simple Extention
    class Fork < Thread
      include Msg
      def initialize(tname, layer, id, type = nil)
        @layer = layer
        @id = id
        th = super { ___do_proc(id) { yield } }
        th.update(layer: layer, name: tname, id: id, type: type)
        Threads.add(th)
      end

      private

      def ___do_proc(id)
        Thread.pass
        verbose { "Initiate Thread #{id}" }
        yield
      rescue Exception
        errmsg
      end
    end

    # Thread with Loop
    class Loop < Fork
      def initialize(tname, layer, id, type = nil)
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
      def initialize(tname, layer, id, type = nil)
        @que = Queue.new
        super { loop { yield @que } }
      end

      def push(str) # returns self
        warning("Thread [#{self[:name]}] is not running") unless alive?
        @que.push(str)
        self
      end

      def shift
        @que.shift
      end

      def empty?
        @que.empty?
      end

      def clear
        @que.clear
        self
      end
    end
  end
end
