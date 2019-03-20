#!/usr/bin/env ruby
require 'libenumx'
require 'thread'

# Add hash manipulate feature to Thread
class Thread
  def update(hash)
    hash.each { |k, v| self[k.to_sym] = v if v }
    self
  end

  def to_hash
    keys.each_with_object(status: status) { |k, h| h[k] = self[k] }
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
      Thread.list.map(&:to_hash).extend(View)
    end

    def killall
      Threads.list.each(&:kill)
    end

    # Thread List View module
    module View
      include Enumx

      # narrow down
      def view(reg = '.')
        map do |h|
          str = "[#{h[:status]}]"
          str += %i(id layer name port).map { |id| h[id] }.compact.join(':')
          str += "(#{h[:type]})" if h[:type]
          str
        end.grep(/#{reg}/).sort.join("\n")
      end
    end

    # Simple Extention
    class Fork < Thread
      include Msg
      def initialize(tname, layer, id, atrb = {})
        @layer = layer
        @id = id
        th = super { ___do_proc(id) { yield } }
        th.update(layer: layer, name: tname, id: id).update(atrb)
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
      def initialize(tname, layer, id, atrb = {})
        super do
          loop do
            yield
            verbose { "Next for #{Thread.current[:name]}" }
          end
        end
      end
    end

    # Queue Thread with Loop
    class QueLoop < Loop
      attr_reader :que
      def initialize(tname, layer, id, atrb = {})
        @que = Queue.new
        super { yield @que }
      end
    end
  end
end
