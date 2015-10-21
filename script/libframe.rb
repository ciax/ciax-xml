#!/usr/bin/ruby
require 'libmsg'

module CIAX
  # Frame Layer
  module Frm
    # For Command/Response Frame
    class Frame
      include Msg
      attr_reader :cc
      # terminator: used for detecting end of stream, cut off before processing in Frame#set(). 
      #             never being included in CC range
      # delimiter: cut 'variable length data' by delimiter
      #             can be included in CC range
      def initialize(endian = nil, ccmethod = nil, terminator = nil)
        @cls_color = 11
        @endian = endian
        @ccrange = nil
        @method = ccmethod
        @terminator = esc_code(terminator)
        reset
      end

      # For Command
      def reset
        @frame = ''
        verbose { 'Reset' }
        self
      end

      # For Command
      def add(frame, e = {})
        if frame
          code = encode(e, frame)
          @frame << code
          @ccrange << code if @ccrange
          verbose { "Add [#{frame.inspect}]" }
        end
        self
      end

      def copy
        verbose { "Copy [#{@frame.inspect}]" }
        @frame
      end

      # For Response
      def set(frame = '')
        if frame && !frame.empty?
          verbose { "Set [#{frame.inspect}]" }
          @frame = @terminator ? frame.split(@terminator).shift : frame
        end
        self
      end

      # Cut frame and decode
      # If param includes 'val' key, it checks value  only
      # If cut str incldes terminetor, str will be trimmed
      def cut(e0)
        verbose { "Cut Start for [#{@frame.inspect}](#{@frame.size})" }
        return verify(e0) if e0['val'] # Verify value
        len = e0['length']
        del = e0['delimiter']
        if len
          verbose { "Cut by Size [#{len}]" }
          if len.to_i > @frame.size
            alert("Cut reached end [#{@frame.size}/#{len}] ")
            str=@frame
            cc_add(str)
          else
            str = @frame.slice!(0, len.to_i)
            cc_add(str)
          end
        elsif del
          dlm = esc_code(del).to_s
          verbose { "Cut by Delimiter [#{dlm.inspect}]" }
          str, dlm, @frame = @frame.partition(dlm)
          cc_add(str+dlm)
        else
          verbose { 'Cut all the rest' }
          str=@frame
          cc_add(str)
        end
        if str.empty?
          alert('Cut Empty')
          return ''
        end
        len = str.size
        verbose { "Cut String: [#{str.inspect}]" }
        # Pick Part
        r = e0['slice']
        if r
          str = str.slice(*r.split(':').map(&:to_i))
          verbose { "Pick: [#{str.inspect}] by range=[#{r}]" }
        end
        decode(e0, str)
      end

      # Check Code
      def cc_add(str) # Add to check code
        @ccrange << str if @ccrange
        verbose { "Cc Add to Range Frame [#{str.inspect}]" }
        self
      end

      def cc_mark # Check Code Start
        verbose { 'Cc Mark Range Start' }
        @ccrange = ''
        self
      end

      def cc_set # Check Code End
        verbose { "Cc Frame [#{@ccrange.inspect}]" }
        chk = 0
        case @method
        when 'len'
          chk = @ccrange.length
        when 'bcc'
          @ccrange.each_byte { |c| chk ^= c }
        when 'sum'
          @ccrange.each_byte { |c| chk += c }
          chk %= 256
        else
          Msg.cfg_err("No such CC method #{@method}")
        end
        verbose { "Cc Calc [#{@method.upcase}] -> (#{chk})" }
        @ccrange = nil
        @cc = chk.to_s
      end

      def cc_check(cc)
        return self unless cc
        if cc == @cc
          verbose { "Cc Verify OK [#{cc}]" }
        else
          cc_err("CC Mismatch:[#{cc}] (should be [#{@cc}]) in [#{@ccrange.inspect}]")
        end
        self
      end

      private

      def verify(e0)
        ref = e0['val']
        len = e0['length'] || ref.size
        str = @frame.slice!(0, len.to_i)
        if e0['decode']
          val = decode(e0, str)
          ref = expr(ref).to_s
        else
          val = str
        end
        if ref == val
          verbose { "Verify:(#{e0['label']}) [#{ref.inspect}] OK" }
        else
          cc_err("Mismatch(#{e0['label']}):[#{val.inspect}] (should be [#{ref.inspect}])")
        end
        cc_add(str)
        str
      end

      def decode(e0, code) # Chr -> Num
        cdc = e0['decode']
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
          ary = code.unpack('C*')
          ary.reverse! if @endian == 'little'
          num = ary.inject(0) { |a, e| a * 256 + e }
          base = 256
        end
        case e0['sign']
        when 'msb'
          range = base**code.size
          num = num < range / 2 ? num : num - range
        end
        verbose { "Decode:(#{cdc}) [#{code.inspect}] -> [#{num}]" }
        num.to_s
      end

      def encode(e0, str) # Num -> Chr
        str = e0['format'] % expr(str) if e0['format']
        len = e0['length']
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
