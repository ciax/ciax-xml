#!/usr/bin/ruby
require 'libsimslo'

module CIAX
  # Device Simulator
  module Simulator
    # Slosyn Driver Simulator
    class Carousel < Slosyn
      def initialize
        super(10_002)
        @axis = Axis.new(-235, 5, 12)
      end

      def slo_in(num)
        super
        return '0' unless num.to_i == 1
        (@axis.pulse % 10 == 0) ? '1' : '0'
      end
    end

    if __FILE__ == $PROGRAM_NAME
      sv = Carousel.new(*ARGV)
      sv.serve
      sleep
    end
  end
end
