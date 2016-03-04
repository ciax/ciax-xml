#!/usr/bin/ruby
require 'libsim'

module CIAX
  module Simulator
    # Motor Axis Simulator
    class Axis
      attr_accessor :spd
      attr_reader :pulse, :bs, :help
      def initialize(p_min = 0, p_max = 9999, spd = 1)
        @p_min = p_min
        @p_max = p_max
        @spd = spd
        @pulse = 0
        @bs = 0 # Busy status
      end

      def servo(target)
        Thread.new(target.to_i) do |t|
          @bs = 1
          loop do
            diff = t - @pulse
            @bs = 0 if diff == 0
            break if @bs == 0
            pulse = (@pulse + (diff <=> 0))
            sleep 0.1
          end
        end
      end

      def pulse=(num)
        if num > @p_max
          num = @p_min
        elsif num < @p_min
          num = @p_max
        end
        @pulse = num
      end

      def stop
        @bs = 0
      end
    end
  end
end
