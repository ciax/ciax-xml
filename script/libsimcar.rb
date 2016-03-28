#!/usr/bin/ruby
require 'libsimslo'

module CIAX
  # Device Simulator
  module Simulator
    # Slosyn Driver Simulator
    class Carousel < Slosyn
      def initialize
        super(-23.49, 0.41, 12, 10_004)
      end

      def slo_in(num)
        super
        _sw_by_axis(num.to_i) ? '1' : '0'
      end

      private

      def _sw_by_axis(num)
        case num
        when 1
          @axis.pulse % 1_000_000 == 0
        when 3
          @axis.up_limit?
        when 4
          @axis.dw_limit?
        else
          false
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      sv = Carousel.new(*ARGV)
      sv.serve
      sleep
    end
  end
end
