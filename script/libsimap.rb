#!/usr/bin/ruby
# A/D Simulator
require 'libsim'
module CIAX
  # Device Simulater
  module Simulator
    # Simulation Server
    class Ap < Server
      def initialize(port = 10002, *args)
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

    if __FILE__ == $PROGRAM_NAME
      Ap.new(*ARGV).serve
    end
  end
end
