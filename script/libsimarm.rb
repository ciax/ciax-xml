#!/usr/bin/ruby
require 'libsimslo'

module CIAX
  # Device Simulator
  module Simulator
    # Slosyn Driver Simulator
    class Arm < Slosyn
      def initialize
        super(-0.3, 185.3, 1, 10_003)
        @tol = 500
        @postbl = [123, 12.8, 200.5, 0, 185]
      end

      def cmd_in(num)
        super
        about(@postbl[num.to_i - 1])
      end

      private

      def about(x) # torerance
        pos = x * 1000
        (@axis.pulse - pos).abs < @tol ? '1' : '0'
      end
    end

    if __FILE__ == $PROGRAM_NAME
      Arm.new(*ARGV).serve
    end
  end
end
