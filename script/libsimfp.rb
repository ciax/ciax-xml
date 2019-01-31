#!/usr/bin/env ruby
# I/O Simulator
require 'libsimio'

module CIAX
  # Device Simulator
  module Simulator
    # Field Point I/O
    class FpDio < Server
      def initialize(cfg = nil)
        super(10_001, cfg)
        @dev_dic[:fp] = self
        @ifs = "\n"
        @ofs = "\r"
        # @reg[2]: output, @reg[3]: input
        @reg = [0, 0, 5268, 1366].map { |n| Word.new(n) }
        # Input[index] vs Output[value] table with time delay
        # GV(0-1),ArmRot(2-3),RoboH1(4-7),RoboH2(8-11)
        @drvtbl = [
          [6, 4], [7, 4], [12, 2], [13, 2], [2, 0.3], [3, 0.3],
          [2, 0.3], [3, 0.3], [4, 0.3], [5, 0.3], [4, 0.3], [5, 0.3]
        ]
      end

      # For Contact Sensor
      # Arm Catcher Close? (bit10)
      def arm_close?
        @reg[2][10] == 1
      end

      #  RoboHand Close? (bit2,4)
      def rh_close?
        bin = @reg[2]
        [2, 4].all? { |d| bin[d] == 1 }
      end

      # Switch Load/Store mode with Catcher O/C at ArmPos = STORE
      def change_mode(hexstr)
        case hexstr
        when '0C000400' # AC
          @mask_load = true
          log('Loading Mode')
        when '0C000800' # AO
          @mask_load = false
          log('Stored Mode')
        end
      end

      def arm_oc(idx, hexstr)
        log(@dev_dic.keys.inspect)
        # OUTPUT?
        return unless idx == 2 && @dev_dic.key?(:arm)
        # ARM:STORE position?
        return unless @dev_dic[:arm].fpos > 200
        change_mode(hexstr)
      end

      private

      def _dispatch(str)
        case str
        when /^>0([0-3])!J..$/
          # Input
          ___make_base(Regexp.last_match(1).to_i)
        when /^>0([0-3])!L([0-9A-F]{10})$/
          # Output
          ___manipulate_io(Regexp.last_match(1).to_i, Regexp.last_match(2))
        else
          'E_INVALID_CMD'
        end
      end

      # output = 2, input = 3
      def ___make_base(idx)
        'A' + @reg[idx].to_x + @reg[idx].xbcc
      end

      def ___manipulate_io(idx, par)
        cmask = par[0, 4].hex
        data = par[4, 4].hex
        arm_oc(idx, par[0, 8])
        @reg[idx].mask(cmask, data)
        ___delay_input
        'A'
      end

      def ___delay_input
        input = @reg[3]
        output = @reg[2]
        @drvtbl.each_with_index do |p, i|
          o, dly = p
          next if input[i] == output[o]
          Thread.new do
            sleep dly
            input[i] = output[o]
          end
        end
      end
    end

    @sim_list << FpDio

    FpDio.new.serve if __FILE__ == $PROGRAM_NAME
  end
end
