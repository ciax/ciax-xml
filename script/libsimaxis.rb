#!/usr/bin/ruby
require 'libsim'

module CIAX
  module Simulator
    # Motor Axis Simulator
    class Axis
      attr_accessor :speed, :hardlim
      attr_reader :pulse, :busy, :help
      def initialize(hl_min = -999_999, hl_max = 999_999, spd = 1_000)
        Msg.cfg_err('Limit Max < Min') if hl_min > hl_max
        @hl_min = hl_min
        @hl_max = hl_max
        @max_range = 1_000_000_000
        @pulse = 0
        @speed = spd # 1000 pulse per second
        @hardlim = true # Hardware Limit
      end

      def servo(target)
        return unless _in_limit?
        Thread.new(target.to_i) do |t|
          @busy = true
          while @busy
            @pulse += (t <=> @pulse)
            @busy = _upd_busy(t)
            sleep 0.5 / @speed # Consider the processor speed
          end
        end
      end

      def jog(dir = 1)
        dir = dir.to_i
        return if dir == 0
        servo(dir.abs * @max_range)
      end

      def pulse=(num)
        @pulse = [[num, @max_range].min, -@max_range].max
      end

      def stop
        @busy = nil
      end

      def up_limit?
        @pulse > @hl_max
      end

      def dw_limit?
        @pulse < @hl_min
      end

      private

      def _upd_busy(t)
        t != @pulse && _in_range? && _in_limit?
      end

      def _in_range?
        (-@max_range..@max_range).cover?(@pulse)
      end

      def _in_limit?
        return true unless @hardlim
        (@hl_min..@hl_max).cover?(@pulse)
      end
    end
  end
end
