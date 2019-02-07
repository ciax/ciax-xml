#!/usr/bin/env ruby
require 'libmsg'
module CIAX
  # Frame Layer
  module Frm
    # For Codec module
    class Codec
      include Msg
      def initialize(endian)
        # endian is 'big' or 'little'
        @endian = endian
      end

      def decode(code, e0) # Chr -> Num
        cdc = e0[:decode]
        return code.to_s unless cdc
        num, base = ___num_by_type(code, cdc)
        if e0[:sign] == 'msb'
          range = base**code.size
          num = num < range / 2 ? num : num - range
        end
        verbose { "Decode:(#{cdc}) [#{code.inspect}] -> [#{num}]" }
        num.to_s
      end

      def encode(str, e0) # Num -> Chr
        str = e0[:format] % expr(str) if e0[:format]
        ___conv_len(e0[:length], str)
      end

      private

      def ___conv_len(len, str)
        return str unless len
        code = ''
        num = expr(str)
        len.to_i.times do
          c = (num % 256).chr
          num /= 256
          code = @endian == 'little' ? code + c : c + code
        end
        verbose { "Encode:[#{str}](#{len}) -> [#{code.inspect}]" }
        code
      end

      def ___num_by_type(code, type)
        method("_dec_#{type}").call(code)
      rescue NameError
        ___dec_integer(code)
      end

      def _dec_hexstr(code) # "FF" -> "255"
        [code.hex, 16]
      end

      def _dec_decstr(code) # "80000123" -> "-123"
        # sign: k3n=F, oss=8,
        sign = /[8Ff]/ =~ code.slice!(0) ? '-' : ''
        code.sub!(/^0+/, '')
        num = code.empty? ? '0' : sign + code
        [num, 10]
      end

      def _dec_binstr(code)
        num = [code].pack('b*').ord
        [num, 2]
      end

      def ___dec_integer(code)
        # integer
        ary = code.unpack('C*')
        ary.reverse! if @endian == 'little'
        num = ary.inject(0) { |a, e| a * 256 + e }
        [num, 256]
      end
    end
  end
end
