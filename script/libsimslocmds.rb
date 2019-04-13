#!/usr/bin/env ruby
require 'libsimaxis'

module CIAX
  # Device Simulator
  module Simulator
    # Slosyn Driver Simulator
    module SlosynCommands
      # Status Commands
      # Re-reading err will be '0'
      def _cmd_err
        if @axis.up_limit?
          @on = @on ? '0' : '128'
        elsif @axis.dw_limit?
          @on = @on ? '0' : '129'
        else
          @on = nil
          '0'
        end
      end

      def _cmd_busy
        @axis.busy ? 1 : 0
      end

      # in(3) is + Limit
      # in(4) is - Limit
      def _cmd_in(int)
        _get_in(int) ? '1' : '0'
      end

      def _cmd_speed
        _to_real(@axis.speed)
      end

      def _cmd_abspos
        str = _to_real(@axis.pulse)
        # Simulate Invalid String (Probability 0.3%)
        str = str[0..2] + '?' if rand < 0.003
        str
      end

      # Config Command
      def _cmd_hardlimoff
        @axis.hardlim = false
        @prompt_ok
      end

      def _cmd_hardlimon
        @axis.hardlim = true
        @prompt_ok
      end

      def _cmd_speed=(real)
        @axis.speed = _to_int(real)
        @prompt_ok
      end

      def _cmd_abspos=(real)
        @axis.pulse = _to_int(real)
        @prompt_ok
      end

      # Motion Command
      def _cmd_jog=(sign) # sign= 1,-1
        return unless sign.to_i.abs == 1
        @axis.jog(sign.to_i)
        @prompt_ok
      end

      def _cmd_movea=(real)
        @axis.servo(_to_int(real))
        @prompt_ok
      end

      def _cmd_movei=(real)
        @axis.servo(@axis.pulse + _to_int(real))
        @prompt_ok
      end

      def _cmd_stop
        @axis.stop
        @prompt_ok
      end

      alias _cmd_bs _cmd_busy
      alias _cmd_hl0 _cmd_hardlimoff
      alias _cmd_hl1 _cmd_hardlimon
      alias _cmd_spd _cmd_speed
      alias _cmd_p _cmd_abspos
      alias _cmd_spd= _cmd_speed=
      alias _cmd_p= _cmd_abspos=
      alias _cmd_j= _cmd_jog=
      alias _cmd_ma= _cmd_movea=
      alias _cmd_mi= _cmd_movei=
    end
  end
end
