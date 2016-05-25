#!/usr/bin/ruby
require 'libsimaxis'

module CIAX
  # Device Simulator
  module Simulator
    # Slosyn Driver Simulator
    class Slosyn < Server
      def initialize(dl = -100, ul = 100, spd = 1, port = 10_000, cfg = nil)
        super(port, cfg)
        @ifs = "\n"
        @ofs = "\r\n"
        @axis = Axis.new(to_int(dl), to_int(ul), to_int(spd))
        # wn: drive ON/OFF during stop
        @io = { wn: '1', e1: '0', e2: '0' }
      end

      def fpos # returns float
        @axis.absp.to_f / 1_000
      end

      private

      def method_call(str)
        cmd = 'cmd_' + str
        if /=/ =~ cmd
          method("#{$`}=").call($')
        elsif /\((.*)\)/ =~ cmd
          method($`).call(Regexp.last_match(1))
        else
          method(cmd).call
        end || @prompt_ng
      end

      def to_int(real)
        (real.to_f * 1_000).to_i
      end

      def to_real(int)
        format('%.6f', int.to_f / 1_000)
      end

      public

      # Status Commands
      # Re-reading err will be '0'
      def cmd_err
        if @axis.up_limit?
          @on = @on ? '0' : '128'
        elsif @axis.dw_limit?
          @on = @on ? '0' : '129'
        else
          @on = nil
          '0'
        end
      end

      def cmd_busy
        @axis.busy ? 1 : 0
      end

      # in(3) is + Limit
      # in(4) is - Limit
      def cmd_in(int)
        return unless (1..4).include?(int)
        '0'
      end

      def cmd_speed
        to_real(@axis.speed)
      end

      def cmd_abspos
        to_real(@axis.pulse)
      end

      def cmd_help
        methods.map(&:to_s).grep(/^cmd_/).map do |s|
          s.sub(/^cmd_/, '')
        end.join($INPUT_RECORD_SEPARATOR)
      end

      # Config Command
      def cmd_hardlimoff
        @axis.hardlim = false
        @prompt_ok
      end

      def cmd_hardlimon
        @axis.hardlim = true
        @prompt_ok
      end

      def cmd_speed=(real)
        @axis.speed = to_int(real)
        @prompt_ok
      end

      def cmd_abspos=(real)
        @axis.pulse = to_int(real)
        @prompt_ok
      end

      # Motion Command
      def cmd_jog=(sign) # sign= 1,-1
        return unless sign.to_i.abs == 1
        @axis.jog(sign.to_i)
        @prompt_ok
      end

      def cmd_movea=(real)
        @axis.servo(to_int(real))
        @prompt_ok
      end

      def cmd_movei=(real)
        @axis.servo(@axis.pulse + to_int(real))
        @prompt_ok
      end

      def cmd_stop
        @axis.stop
        @prompt_ok
      end

      alias_method :cmd_bs, :cmd_busy
      alias_method :cmd_hl0, :cmd_hardlimoff
      alias_method :cmd_hl1, :cmd_hardlimon
      alias_method :cmd_spd, :cmd_speed
      alias_method :cmd_p, :cmd_abspos
      alias_method :cmd_spd=, :cmd_speed=
      alias_method :cmd_p=, :cmd_abspos=
      alias_method :cmd_j=, :cmd_jog=
      alias_method :cmd_ma=, :cmd_movea=
      alias_method :cmd_mi=, :cmd_movei=
    end

    if __FILE__ == $PROGRAM_NAME
      sv = Slosyn.new
      sv.serve
      sleep
    end
  end
end
