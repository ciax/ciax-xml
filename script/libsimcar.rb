#!/usr/bin/ruby
require 'libsimslo'

module CIAX
  # Device Simulator
  module Simulator
    # Slosyn Driver Simulator
    class Carousel < Slosyn
      def initialize(cfg = nil)
        super(-23.49, 0.41, 12, 10_004, cfg)
        @axis.timeout = 10
        _set_in(1) { _contact_sensor? }
        _set_in(3) { @axis.up_limit? }
        _set_in(4) { @axis.dw_limit? }
      end

      private

      # Contact sensor (off if load mode)
      def _contact_sensor?
        !@mask_load ||
          ((@axis.pulse % 1000).zero? &&
           (fp = @devlist[:fp]) && fp.arm_close? &&
           (arm = @devlist[:arm]) && arm.fpos > 150)
      end
    end

    @sim_list << Carousel

    Carousel.new.serve if __FILE__ == $PROGRAM_NAME
  end
end
