#!/usr/bin/ruby
require 'libsimslo'

module CIAX
  # Device Simulator
  module Simulator
    # Slosyn Driver Simulator
    class Carousel < Slosyn
      def initialize(cfg = nil)
        super(-23.49, 0.41, 12, 10_004, cfg)
        @list = @cfg[:list]
      end

      def cmd_in(num)
        super
        _sw_by_axis(num.to_i) ? '1' : '0'
      end

      private

      def _sw_by_axis(num)
        case num
        when 1
          # Contact sensor (off if load mode)
          _contact
        when 3
          @axis.up_limit?
        when 4
          @axis.dw_limit?
        else
          false
        end
      end

      def _contact
        return unless @axis.pulse % 1000 == 0
        return true unless @list[:load]
        return true if @list[:fp].arm_close? && @list[:arm].fpos > 150
        false
      end
    end

    Carousel.new.serve if __FILE__ == $PROGRAM_NAME
  end
end
