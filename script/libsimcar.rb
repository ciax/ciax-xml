#!/usr/bin/env ruby
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
           (fp = @dev_dic[:fp]) && fp.arm_close? &&
           (arm = @dev_dic[:arm]) && arm.fpos > 150)
      end
    end

    @sim_list << Carousel

    Carousel.new.serve if $PROGRAM_NAME == __FILE__
  end
end
