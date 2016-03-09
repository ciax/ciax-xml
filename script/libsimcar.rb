#!/usr/bin/ruby
require 'libsimslo'

module CIAX
  # Device Simulator
  module Simulator
    # Slosyn Driver Simulator
    class Carousel < Slosyn
      def initialize
        super(-23.5, 0.5, 12, 10_004)
      end

      def slo_in(num)
        super
        return '0' unless num.to_i == 1
        (@axis.pulse % 1_000_000 == 0) ? '1' : '0'
      end
    end

    if __FILE__ == $PROGRAM_NAME
      sv = Carousel.new(*ARGV)
      sv.serve
      sleep
    end
  end
end
