#!/usr/bin/ruby
require 'libsim'

module CIAX
  module Simulator
    # Motor Axis Simulator
    class Axis
      attr_accessor :speed, :hardlim
      attr_reader :absp, :pulse, :busy, :help
      def initialize(hl_min = -999_999, hl_max = 999_999, spd = 1_000)
        Msg.cfg_err('Limit Max < Min') if hl_min > hl_max
        @hl_min = hl_min
        @hl_max = hl_max
        @max_range = 1_000_000_000
        @pulse = 0
        @absp = 0
        @speed = spd # 1000 pulse per second
        @hardlim = true # Hardware Limit
      end

      def servo(target)
        return unless _in_range?
        target = _regulate_(target)
        Thread.new(target.to_i) do |t|
          @busy = true
          while @busy
            _toward_target_(t)
            @busy = _upd_busy_(t)
            sleep 0.1 # Consider the processor speed
          end
        end
      end

      def jog(dir = 1)
        dir = dir.to_i
        return if dir.zero?
        servo(dir * @max_range)
      end

      def pulse=(num)
        @pulse = [[num, @max_range].min, -@max_range].max
      end

      def stop
        @busy = nil
      end

      def up_limit?
        @absp >= @hl_max
      end

      def dw_limit?
        @absp <= @hl_min
      end

      private

      def _toward_target_(tgt)
        inc = [(tgt - @absp).abs, @speed / 10].min
        dif = (tgt <=> @absp) * inc
        @pulse += dif
        @absp += dif
      end

      def _upd_busy_(t)
        t != @absp && _in_range?
      end

      def _in_range?
        (-@max_range..@max_range).cover?(@absp)
      end

      def _regulate_(target)
        target += (@absp - @pulse)
        return target unless @hardlim
        if target > @hl_max
          [@hl_max, @absp].max
        elsif target < @hl_min
          [@hl_min, @absp].min
        else
          target
        end
      end
    end
  end
end
