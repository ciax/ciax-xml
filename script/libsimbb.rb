#!/usr/bin/ruby
require 'libsimio'

module CIAX
  # Device Simulator
  module Simulator
    # BB Electric I/O
    class BBIO < GServer
      def initialize(port = 10_007, *args)
        super(port, *args)
        Thread.abort_on_exception = true
        @ioreg = Word.new(0)
      end

      def serve(io)
        while (str = io.readpartial(6))
          sleep 0.1
          res = dispatch(str)
          io.print res if res
        end
      rescue
        warn $ERROR_INFO
      end

      private

      def dispatch(str)
        case str
        # getstat
        when /^!0RD/
          @ioreg.to_cb
        when /^!0SO/
          num = $'.unpack('n*').first
          @ioreg = Word.new(num)
          nil
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      sv = BBIO.new(*ARGV)
      sv.start
      sleep
    end
  end
end
