#!/usr/bin/ruby
require 'libsimslo'

module CIAX
  # Device Simulator
  module Simulator
    # Slosyn Driver Simulator
    class Arm < Slosyn
      def initialize(cfg = nil)
        super(-0.3, 185.3, 2.5, 10_003, cfg)
        @tol = 600
        @postbl = [123, 12.8, 200.5, 0, 185]
      end

      # IN 1: ROT
      # IN 2: FOCUS
      # IN 3: STORE
      # IN 4: INI
      # IN 5: CON
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

    Arm.new.serve if __FILE__ == $PROGRAM_NAME
  end
end
