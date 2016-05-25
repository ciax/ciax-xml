#!/usr/bin/ruby
require 'libsimslo'

module CIAX
  # Device Simulator
  module Simulator
    # Slosyn Driver Simulator
    class Arm < Slosyn
      def initialize(cfg = nil)
        super(-0.3, 200.5, 2.5, 10_003, cfg)
        @list = @cfg[:list]
        @list[:arm] = self
        @tol = 600
        @postbl = [123, 12.8, 200.5, 0, 12.8]
      end

      # IN 1: ROT  (123)
      # IN 2: FOCUS(12.8)
      # IN 3: STORE(200.5)
      # IN 4: INI  (0)
      #     : WAIT (185)
      # IN 5: CON
      def cmd_in(numstr)
        super
        if numstr == '5'
          _contact? ? '1' : '0'
        else
          about(@postbl[numstr.to_i - 1])
        end
      end

      private

      def about(x) # torerance
        pos = x * 1000
        (@axis.pulse - pos).abs < @tol ? '1' : '0'
      end

      # Contact Sensor (Both Arm & RH close during Loading at Focus)
      def _contact?
        return unless @list.key?(:fp) && @list[:load]
        fp = @list[:fp]
        return unless fp.arm_close?
        # At Wait~Store && ARM Close
        return true if fpos > 185
        # At FOCUS && RH,ARM Close
        about(12.8) && fp.rh_close?
      end
    end

    Arm.new.serve if __FILE__ == $PROGRAM_NAME
  end
end
