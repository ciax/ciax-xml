#!/usr/bin/ruby
# I/O Simulator
require 'libsimio'

module CIAX
  module Simulator
    # Field Point I/O
    class FPIO < GServer
      def initialize(port = 10_002, *args)
        super(port, *args)
        Thread.abort_on_exception = true
        # @reg[2]: output, @reg[3]: input
        @reg = [0, 0, 5268, 1366].map { |n| Word.new(n) }
        # Input[index] vs Output[value] table
        # GV(0-1),ArmRot(2-3),RoboH1(4-7),RoboH2(8-11)
        @drvtbl = [6, 7, 12, 13, 2, 3, 2, 3, 4, 5, 4, 5]
      end

      def serve(io = nil)
        selectio(io)
        while (str = gets.chomp)
          sleep 0.1
          print dispatch(str).to_s + $/
        end
      rescue
        warn $ERROR_INFO
      end

      private

      def selectio(io)
        return unless io
        $stdin = $stdout = io
        $/ = "\r"
      end

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
          next if input[i] == output[p]
          Thread.new do
            sleep(i < 4 ? 1 : 0)
            input[i] = output[p]
          end
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      sv = FPIO.new(*ARGV)
      sv.serve
      sleep
    end
  end
end
