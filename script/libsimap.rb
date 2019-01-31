#!/usr/bin/env ruby
# Omega Air Pressure Sensor Simulator
require 'libsim'
module CIAX
  # Device Simulater
  module Simulator
    # Simulation Server
    class Ap < Server
      def initialize(cfg = nil)
        super(10_002, cfg)
        @ifs = @ofs = "\r"
      end

      private

      def _dispatch(str)
        if str == '*00P1'
          x = 94
          6.times { x += rand }
          format('?01CP=%06.2f', x)
        else
          '?'
        end
      end
    end

    @sim_list << Ap

    Ap.new.serve if __FILE__ == $PROGRAM_NAME
  end
end
