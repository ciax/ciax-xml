#!/usr/bin/env ruby
require 'libsim'

module CIAX
  module Simulator
    # Motor Axis Simulator
    class Axis
      # :timeout for error test
      attr_accessor :speed, :hardlim, :timeout
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
        @start_time = Time.now.to_i
      end

      def servo(target)
        return unless __in_range?
        Thread.new(___regulate(target).to_i) do |t|
          @start_time = Time.now.to_i
          @busy = true
          while @busy
            ___toward_target(t)
            @busy = ___upd_busy(t)
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

      def ___toward_target(tgt)
        inc = [(tgt - @absp).abs, @speed / 10].min
        dif = (tgt <=> @absp) * inc
        @pulse += dif
        @absp += dif
      end

      def ___upd_busy(t)
        t != @absp && __in_range? && !___timeout?
      end

      def ___timeout?
        return unless @timeout
        Time.now.to_i > @timeout + @start_time
      end

      def __in_range?
        (-@max_range..@max_range).cover?(@absp)
      end

      def ___regulate(target)
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
