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
        @axis = Axis.new(-3, 1853, 0.1)
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

      def setdec(n)
        (n.to_f * 10).to_i
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
          @axis.speed = num
        else
          @axis.speed
        end
      end

      def slo_abspos(num = nil)
        if num
          @axis.pulse = setdec(num)
        else
          format('%.1f', @axis.pulse.to_f / 10)
        end
      end

      # Motion Command
      def slo_jog(num)
        @axis.jog(num.to_i)
      end

      def slo_movea(num)
        @axis.servo(setdec(num))
      end

      def slo_movei(num)
        @axis.servo(@axis.pulse + setdec(num))
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
