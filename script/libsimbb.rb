#!/usr/bin/ruby
require 'libsimio'

module CIAX
  # Device Simulator
  module Simulator
    # BB Electric I/O
    class BBIO < Server
      def initialize(port = 10_007, *args)
        super(port, *args)
        @ioreg = Word.new(0)
        @length = 6
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

    BBIO.new(*ARGV).serve if __FILE__ == $PROGRAM_NAME
  end
end
