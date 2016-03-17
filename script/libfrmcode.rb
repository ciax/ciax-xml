#!/usr/bin/ruby
require 'libmsg'

module CIAX
  # Frame Layer
  module Frm
    # For Command/Response Frame
    module Codec
      attr_reader :endian
      def decode(code, e0) # Chr -> Num
        cdc = e0[:decode]
        return code.to_s unless cdc
        case cdc
        when 'hexstr' # "FF" -> "255"
          num = code.hex
          base = 16
        when 'decstr' # "80000123" -> "-123"
          # sign: k3n=F, oss=8,
          sign = (/[8Ff]/ =~ code.slice!(0)) ? '-' : ''
          code.sub!(/^0+/, '')
          num = code.empty? ? '0' : sign + num
          base = 10
        when 'binstr'
          num = [code].pack('b*').ord
          base = 2
        else
          # integer
          ary = code.unpack('C*')
          ary.reverse! if @endian == 'little'
          num = ary.inject(0) { |a, e| a * 256 + e }
          base = 256
        end
        case e0[:sign]
        when 'msb'
          range = base**code.size
          num = num < range / 2 ? num : num - range
        end
        verbose { "Decode:(#{cdc}) [#{code.inspect}] -> [#{num}]" }
        num.to_s
      end

      def encode(str, e0) # Num -> Chr
        str = e0[:format] % expr(str) if e0[:format]
        len = e0[:length]
        if len
          code = ''
          num = expr(str)
          len.to_i.times do
            c = (num % 256).chr
            num /= 256
            code = (@endian == 'little') ? code + c : c + code
          end
          verbose { "Encode:[#{str}](#{len}) -> [#{code.inspect}]" }
          str = code
        end
        str
      end
    end
  end
end
