#!/usr/bin/ruby
# I/O Simulator
require 'libsimio'

module CIAX
  # Device Simulator
  module Simulator
    # Field Point I/O
    class FpDio < Server
      def initialize(port = 10_001, *args)
        super
        @separator = "\r"
        # @reg[2]: output, @reg[3]: input
        @reg = [0, 0, 5268, 1366].map { |n| Word.new(n) }
        # Input[index] vs Output[value] table with time delay
        # GV(0-1),ArmRot(2-3),RoboH1(4-7),RoboH2(8-11)
        @drvtbl = [
          [6, 4], [7, 4], [12, 2], [13, 2],
          [2, 0.3], [3, 0.3], [2, 0.3], [3, 0.3],
          [4, 0.3], [5, 0.3], [4, 0.3], [5, 0.3]
        ]
      end

      private

      def dispatch(str)
        case str
        when /^>0([0-3])!J..$/
          make_base(Regexp.last_match(1).to_i)
        when /^>0([0-3])!L([0-9A-F]{10})$/
          manipulate(Regexp.last_match(1).to_i, Regexp.last_match(2))
        else
          'E_INVALID_CMD'
        end
      end

      # output = 2, input = 3
      def make_base(idx)
        'A' + @reg[idx].to_x + @reg[idx].xbcc
      end

      def manipulate(idx, par)
        cmask = par[0, 4].hex
        data = par[4, 4].hex
        @reg[idx].mask(cmask, data)
        servo
        'A'
      end

      def servo
        input = @reg[3]
        output = @reg[2]
        @drvtbl.each_with_index do|p, i|
          o, dly = p
          next if input[i] == output[o]
          Thread.new do
            sleep dly
            input[i] = output[o]
          end
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      sv = FpDio.new(*ARGV)
      sv.serve
      sleep
    end
  end
end
