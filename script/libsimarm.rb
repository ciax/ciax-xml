#!/usr/bin/ruby
require 'libsimslo'

module CIAX
  # Device Simulator
  module Simulator
    # Slosyn Driver Simulator
    class Arm < Slosyn
      def initialize
        super(-0.3, 185.3, 1, 10_003)
        @tol = 5
        @postbl = [1230, 128, 2005, 0, 1850]
      end

      def slo_in(num)
        super
        about(@postbl[num.to_i - 1])
      end

      private

      def about(x) # torerance
        (-@tol..@tol).cover?(@axis.pulse/100 - x) ? '1' : '0'
      end
    end

    if __FILE__ == $PROGRAM_NAME
      sv = Arm.new(*ARGV)
      sv.serve
      sleep
    end
  end
end
