#!/usr/bin/env ruby
require 'libsimslo'

module CIAX
  # Device Simulator
  module Simulator
    # Slosyn Driver Simulator
    class Arm < Slosyn
      def initialize(cfg = nil)
        super(0, 200.5, 2.5, 10_003, cfg)
        @dev_dic[:arm] = self
        @tol = 600
        # IN 1: ROT  (123)
        # IN 2: FOCUS(12.8)
        # IN 3: STORE(200.5) = +Limit
        # IN 4: INIT (0)     = -Limit
        #     : WAIT (185)
        # IN 5: CON
        _set_in(1) { __about(123) }
        _set_in(2) { __about(12.8) }
        _set_in(5) { _contact_sensor? }
      end

      private

      def __about(x) # torerance
        pos = x * 1000
        (@axis.absp - pos).abs < @tol
      end

      # Contact Sensor (Both Arm & RH close during Loading at Focus)
      def _contact_sensor?
        @mask_load && (fp = @dev_dic[:fp]) &&
          # At Wait~Store && ARM Close
          ((fpos > 185 && fp.arm_close?) ||
           # At FOCUS && RH,ARM Close
           (__about(12.8) && fp.rh_close?))
      end
    end

    @sim_list << Arm

    Arm.new.serve if $PROGRAM_NAME == __FILE__
  end
end
