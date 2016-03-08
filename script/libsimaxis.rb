#!/usr/bin/ruby
require 'libsim'

module CIAX
  module Simulator
    # Motor Axis Simulator
    class Axis
      attr_accessor :speed, :hardlim
      attr_reader :pulse, :busy, :help
      def initialize(hl_min = -9999, hl_max = 9999, spd = 10)
        @hl_min = hl_min
        @hl_max = hl_max
        @max_range = 160_000
        @pulse = 0
        @speed = spd # 10 pulse per second
        @hardlim = true # Hardware Limit
      end

      def servo(target)
        return unless _in_limit?
        Thread.new(target.to_i) do |t|
          @busy = true
          while @busy
            @pulse += (t <=> @pulse)
            @busy = _upd_busy(t)
            sleep 1.0 / @speed
          end
        end
      end

      def jog(dir = 1)
        dir = dir.to_i
        return if dir == 0
        servo(dir.abs * @max_range)
      end

      def pulse=(num)
        @pulse = max(min(num, @max_range), -@max_range)
      end

      def stop
        @busy = nil
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
