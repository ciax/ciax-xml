#!/usr/bin/ruby
require 'libsimaxis'

module CIAX
  # Device Simulator
  module Simulator
    # Slosyn Driver Simulator
    module SlosynCommands
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
        @in_procs[int].call ? '1' : '0'
      end

      def cmd_speed
        to_real(@axis.speed)
      end

      def cmd_abspos
        str = to_real(@axis.pulse)
        # Simulate Invalid String (Probability 0.3%)
        str = str[0..2] + '?' if rand < 0.003
        str
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

      alias cmd_bs cmd_busy
      alias cmd_hl0 cmd_hardlimoff
      alias cmd_hl1 cmd_hardlimon
      alias cmd_spd cmd_speed
      alias cmd_p cmd_abspos
      alias cmd_spd= cmd_speed=
      alias cmd_p= cmd_abspos=
      alias cmd_j= cmd_jog=
      alias cmd_ma= cmd_movea=
      alias cmd_mi= cmd_movei=
    end
  end
end
