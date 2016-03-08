#!/usr/bin/ruby
require 'libsimaxis'

module CIAX
  # Device Simulator
  module Simulator
    # Slosyn Driver Simulator
    class Slosyn < Server
      attr_writer :slo_wn
      attr_accessor :slo_e1, :slo_e2
      attr_reader :slo_err
      def initialize(port = 10_001, *args)
        super
        @separator = "\r\n"
        @axis = Axis.new(-3, 1853, 10)
        @tol = 5
        @slo_wn = 1 # Drive ON/OFF during stop
        @slo_err = 0
        @postbl = [1230, 128, 2005, 0, 1850]
      end

      private

      def dispatch(str)
        cmd = 'slo_' + str
        if /=/ =~ cmd
          method($`).call($')
          '>'
        elsif /\((.*)\)/ =~ cmd
          method($`).call(Regexp.last_match(1))
        else
          method(cmd).call
        end
      rescue NameError
        '?'
      end

      def to_int(n)
        (n.to_f * 10).to_i
      end

      def to_dec(n)
        format('%.1f', n.to_f / 10)
      end

      def about(x) # torerance
        (-@tol..@tol).cover?(@axis.pulse - x) ? '1' : '0'
      end

      public

      # Status Commands
      def slo_busy
        @axis.busy ? 1 : 0
      end

      def slo_in(num)
        about(@postbl[num.to_i - 1])
      end

      def slo_help
        methods.map(&:to_s).grep(/^slo_/).map do |s|
          s.sub(/^slo_/, '')
        end.join($INPUT_RECORD_SEPARATOR)
      end

      # Config Command
      def slo_hardlimoff
        @axis.hardlim = false
        '>'
      end

      def slo_hardlimon
        @axis.hardlim = true
        '>'
      end

      def slo_speed(num = nil)
        if num
          @axis.speed = to_int(num)
        else
          to_dec(@axis.speed)
        end
      end

      def slo_abspos(num = nil)
        if num
          @axis.pulse = to_int(num)
        else
          to_dec(@axis.pulse)
        end
      end

      # Motion Command
      def slo_jog(sign) # sign= 1,-1
        @axis.jog(sign.to_i)
      end

      def slo_movea(num)
        @axis.servo(to_int(num))
      end

      def slo_movei(num)
        @axis.servo(@axis.pulse + to_int(num))
      end

      def slo_stop
        @axis.stop
        '>'
      end

      alias_method :slo_bs, :slo_busy
      alias_method :slo_hl0, :slo_hardlimoff
      alias_method :slo_hl1, :slo_hardlimon
      alias_method :slo_spd, :slo_speed
      alias_method :slo_p, :slo_abspos
      alias_method :slo_j, :slo_jog
      alias_method :slo_ma, :slo_movea
      alias_method :slo_mi, :slo_movei
    end

    if __FILE__ == $PROGRAM_NAME
      sv = Slosyn.new(*ARGV)
      sv.serve
      sleep
    end
  end
end
