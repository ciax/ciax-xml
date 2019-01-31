#!/usr/bin/env ruby
require 'libsim'

module CIAX
  # Simulator Module
  module Simulator
    # 16bit data handling
    class Word
      # n = initial number
      def initialize(n = 0)
        @num = n
      end

      def [](pos)
        @num[pos]
      end

      def []=(pos, bin)
        mask(1 << pos, bin << pos)
      end

      def mask(cmask, data = 0) # change bit
        stay = @num & (0xffff ^ cmask)
        @num = stay + data
        self
      end

      def to_x
        format('%04X', @num)
      end

      def to_b
        format('%016b', @num)
      end

      # Big endian
      def to_cb
        [@num].pack('n*')
      end

      # Little endian
      def to_cl
        [@num].pack('v*')
      end

      def to_s
        @num
      end

      def xbcc
        chk = 0
        to_x.each_byte { |c| chk += c }
        format('%02X', chk % 256)
      end
    end
  end
end
