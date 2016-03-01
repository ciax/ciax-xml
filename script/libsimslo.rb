#!/usr/bin/ruby
require 'libsimaxis'

module CIAX
  module Simulator
    # Slosyn Driver Simulator
    class Slosyn < GServer
      attr_accessor :e1, :e2
      attr_reader :err, :hl1, :hl0
      RS = "\r\n"
      POS = [1230, 128, 2005, 0, 1850]
      def initialize(port = 10_001, *args)
        super(port, *args)
        @axis = Axis.new(0, 9999, 0.1, 5)
        @tol = 5
        @err = 0
        @hl1 = @hl0 = '>'
        Thread.abort_on_exception = true
        @help = self.class.methods.inspect
      end

      def serve(io)
        @io = io
        while (cmd = io.gets(RS).chomp)
          sleep 0.1
          begin
            if /=/ =~ cmd
              method($` + $&).call($')
              res '>'
            elsif /\((.*)\)/ =~ cmd
              res method($`).call(Regexp.last_match(1))
            else
              res method(cmd).call
            end
          rescue NameError
            res '?'
          end
        end
      end

      def res(str)
        @io.print str.to_s + RS
      end

      def setdec(n)
        (n.to_f * 10).to_i
      end

      def about(x) # torerance
        (@axis.pulse <= x + @tol && @axis.pulse >= x - @tol) ? '1' : '0'
      end

      # Commands
      def abspos=(num)
        @axis.pulse = setdec(num)
      end

      def p=(num)
        @axis.pulse = setdec(num)
      end

      def p
        format('%.1f', @axis.pulse.to_f / 10)
      end

      def ma=(num)
        servo(setdec(num))
      end

      def mi=(num)
        @axis.servo(@axis.pulse + setdec(num))
      end

      def j=(num)
        case num.to_i
        when 1
          @axis.servo(2005)
        when -1
          @axis.servo(0)
        end
      end

      def stop
        @asix.stop
        '>'
      end

      def in(num)
        about(POS[num.to_i - 1])
      end
    end

    if __FILE__ == $PROGRAM_NAME
      sv = Slosyn.new(*ARGV)
      sv.start
      sleep
    end
  end
end
