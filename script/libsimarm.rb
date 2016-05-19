#!/usr/bin/ruby
require 'libsimslo'

module CIAX
  # Device Simulator
  module Simulator
    # Slosyn Driver Simulator
    class Arm < Slosyn
      def initialize(cfg = nil)
        super(-0.3, 185.3, 2.5, 10_003, cfg)
        @list = cfg[:list]
        @list[:arm] = self
        @tol = 600
        @postbl = [123, 12.8, 200.5, 0, 12.8]
      end

      # IN 1: ROT  (123)
      # IN 2: FOCUS(12.8)
      # IN 3: STORE(200.5)
      # IN 4: INI  (0)
      #     : WAIT (185)
      # IN 5: CON
      def cmd_in(num)
        super
        res = about(@postbl[num.to_i - 1])
        # Contact Sensor (Both Arm & RH close during Loading at Focus)
        if @list.key?(:fp) && num == 5
          res = (@list[:fp].ra_close? && @list[:load]) ? res : '0'
        end
        res
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
