#!/usr/bin/ruby
require 'libsimaxis'

module CIAX
  module Simulator
    # Slosyn Driver Simulator
    class Slosyn < Server
      attr_accessor :fp_e1, :fp_e2
      attr_reader :fp_err, :fp_hl1, :fp_hl0
      def initialize(port = 10_001, *args)
        super
        @separator = "\r\n"
        @axis = Axis.new(0, 9999, 0.1)
        @tol = 5
        @fp_err = 0
        @fp_hl1 = @fp_hl0 = '>'
        @postbl = [1230, 128, 2005, 0, 1850]
      end

      private

      def dispatch(str)
        cmd = 'fp_' + str
        if /=/ =~ cmd
          method($` + $&).call($')
          '>'
        elsif /\((.*)\)/ =~ cmd
          method($`).call(Regexp.last_match(1))
        else
          method(cmd).call
        end
      rescue NameError
        '?'
      end

      def setdec(n)
        (n.to_f * 10).to_i
      end

      def about(x) # torerance
        (@axis.pulse <= x + @tol && @axis.pulse >= x - @tol) ? '1' : '0'
      end

      public

      # Commands
      def fp_abspos=(num)
        @axis.pulse = setdec(num)
      end

      def fp_p=(num)
        @axis.pulse = setdec(num)
      end

      def fp_p
        format('%.1f', @axis.pulse.to_f / 10)
      end

      def fp_ma=(num)
        @axis.servo(setdec(num))
      end

      def fp_mi=(num)
        @axis.servo(@axis.pulse + setdec(num))
      end

      def fp_j=(num)
        case num.to_i
        when 1
          @axis.servo(2005)
        when -1
          @axis.servo(0)
        end
      end

      def fp_stop
        @asix.stop
        '>'
      end

      def fp_in(num)
        about(@postbl[num.to_i - 1])
      end

      def fp_help
        methods.map(&:to_s).grep(/^fp_/).map { |s| s.sub(/^fp_/, '') }.join($INPUT_RECORD_SEPARATOR)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      sv = Slosyn.new(*ARGV)
      sv.serve
      sleep
    end
  end
end
