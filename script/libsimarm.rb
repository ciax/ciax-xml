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
        # IN 1: ROT  (123)
        # IN 2: FOCUS(12.8)
        # IN 3: STORE(200.5) = +Limit
        # IN 4: INIT (0)     = -Limit
        #     : WAIT (185)
        # IN 5: CON
        @in_procs['1'] = proc { _about(123) }
        @in_procs['2'] = proc { _about(12.8) }
        @in_procs['5'] = proc { _contact? }
      end

      private

      def _about(x) # torerance
        pos = x * 1000
        (@axis.absp - pos).abs < @tol
      end

      # Contact Sensor (Both Arm & RH close during Loading at Focus)
      def _contact?
        return unless @list.key?(:fp) && @list[:load]
        fp = @list[:fp]
        return unless fp.arm_close?
        # At Wait~Store && ARM Close
        return true if fpos > 185
        # At FOCUS && RH,ARM Close
        _about(12.8) && fp.rh_close?
      end
    end

    Arm.new.serve if __FILE__ == $PROGRAM_NAME
  end
end
