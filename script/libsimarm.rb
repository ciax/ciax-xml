#!/usr/bin/ruby
require 'libsimslo'

module CIAX
  # Device Simulator
  module Simulator
    # Slosyn Driver Simulator
    class Arm < Slosyn
      def initialize
        super(10_001)
        @axis = Axis.new(-3, 1853, 10)
        @tol = 5
        @postbl = [1230, 128, 2005, 0, 1850]
      end

      def slo_in(num)
        super
        about(@postbl[num.to_i - 1])
      end

      private

      def about(x) # torerance
        (-@tol..@tol).cover?(@axis.pulse - x) ? '1' : '0'
      end
    end

    if __FILE__ == $PROGRAM_NAME
      sv = Arm.new(*ARGV)
      sv.serve
      sleep
    end
  end
end
