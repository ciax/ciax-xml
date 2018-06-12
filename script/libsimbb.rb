#!/usr/bin/ruby
require 'libsimio'

module CIAX
  # Device Simulator
  module Simulator
    # BB Electric I/O
    class BbIo < Server
      def initialize(cfg = nil)
        super(10_007, cfg)
        @ioreg = Word.new(0)
        @length = 6
      end

      private

      def _dispatch(str)
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

    SimList << BbIo

    BbIo.new.serve if __FILE__ == $PROGRAM_NAME
  end
end
