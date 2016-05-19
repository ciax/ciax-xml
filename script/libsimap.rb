#!/usr/bin/ruby
# Omega Air Pressure Sensor Simulator
require 'libsim'
module CIAX
  # Device Simulater
  module Simulator
    # Simulation Server
    class Ap < Server
      def initialize(port = 10_002, *args)
        super
        @separator = "\r"
      end

      private

      def dispatch(str)
        if str == '*00P1'
          x = 94
          6.times { x += rand }
          format('?01CP=%06.2f', x)
        else
          '?'
        end
      end
    end

    Ap.new(*ARGV).serve if __FILE__ == $PROGRAM_NAME
  end
end
