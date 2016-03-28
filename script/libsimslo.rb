#!/usr/bin/ruby
require 'libsimaxis'

module CIAX
  # Device Simulator
  module Simulator
    # Slosyn Driver Simulator
    class Slosyn < Server
      attr_accessor :slo_e1, :slo_e2, :slo_wn
      def initialize(dl = -100, ul = 100, spd = 1, port = 10_000, *args)
        super(port, *args)
        @separator = "\r\n"
        @axis = Axis.new(to_int(dl), to_int(ul), to_int(spd))
        @slo_wn = '1' # Drive ON/OFF during stop
        @slo_err = '0'
      end

      private

      def dispatch(str)
        cmd = 'slo_' + str
        if /=/ =~ cmd
          '>' if method("#{$`}=").call($')
        elsif /\((.*)\)/ =~ cmd
          method($`).call(Regexp.last_match(1))
        else
          method(cmd).call
        end || '?'
      rescue NameError, ArgumentError
        '?'
      end

      def to_int(real)
        (real.to_f * 1_000).to_i
      end

      def to_real(int)
        format('%.6f', int.to_f / 1_000)
      end

      public

      # Status Commands
      def slo_err
        if @axis.up_limit?
          '128'
        elsif @axis.dw_limit?
          '129'
        else
          '0'
        end
      end

      def slo_busy
        @axis.busy ? 1 : 0
      end

      # in(3) is + Limit
      # in(4) is - Limit
      def slo_in(int)
        return unless (1..4).include?(int)
        '0'
      end

      def slo_speed
        to_real(@axis.speed)
      end

      def slo_abspos
        to_real(@axis.pulse)
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

      def slo_speed=(real)
        @axis.speed = to_int(real)
      end

      def slo_abspos=(real)
        @axis.pulse = to_int(real)
      end

      # Motion Command
      def slo_jog=(sign) # sign= 1,-1
        return unless sign.to_i.abs == 1
        @axis.jog(sign.to_i)
      end

      def slo_movea=(real)
        @axis.servo(to_int(real))
      end

      def slo_movei=(real)
        @axis.servo(@axis.pulse + to_int(real))
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
      alias_method :slo_spd=, :slo_speed=
      alias_method :slo_p=, :slo_abspos=
      alias_method :slo_j=, :slo_jog=
      alias_method :slo_ma=, :slo_movea=
      alias_method :slo_mi=, :slo_movei=
    end

    if __FILE__ == $PROGRAM_NAME
      sv = Slosyn.new
      sv.serve
      sleep
    end
  end
end
