#!/usr/bin/ruby
require 'libsimslocmds'

module CIAX
  # Device Simulator
  module Simulator
    # Slosyn Driver Simulator
    class Slosyn < Server
      include SlosynCommands

      def initialize(dl = -100, ul = 100, spd = 1, port = 10_000, cfg = nil)
        super(port, cfg)
        @ifs = "\n"
        @ofs = "\r\n"
        @axis = Axis.new(to_int(dl), to_int(ul), to_int(spd))
        # wn: drive ON/OFF during stop
        @io = { wn: '1', e1: '0', e2: '0' }
        @in_procs = Hash.new(proc {})
        @in_procs['3'] = proc { @axis.up_limit? }
        @in_procs['4'] = proc { @axis.dw_limit? }
      end

      def fpos # returns float
        @axis.absp.to_f / 1_000
      end

      private

      def _method_call(str)
        if /=/ =~ str
          super("#{$`}=", $')
        elsif /\((.*)\)/ =~ str
          super($`, Regexp.last_match(1))
        else
          super(str)
        end
      end

      def to_int(real)
        (real.to_f * 1_000).to_i
      end

      def to_real(int)
        format('%.6f', int.to_f / 1_000)
      end
    end

    Slosyn.new.serve if __FILE__ == $PROGRAM_NAME
  end
end
