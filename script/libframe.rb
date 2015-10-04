#!/usr/bin/ruby
require 'libmsg'

module CIAX
  module Frm
    class Frame # For Command/Response Frame
      include Msg
      attr_reader :cc
      # terminator: frame pointer will jump to terminator if no length or delimiter is specified
      def initialize(endian = nil, ccmethod = nil, terminator = nil)
        @cls_color = 11
        @endian = endian
        @ccrange = nil
        @method = ccmethod
        @terminator = terminator && eval('"' + terminator + '"')
        reset
      end

      # For Command
      def reset
        @frame = ''
        verbose { 'Reset' }
        self
      end

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
      def set(frame = '', length = nil, padding = nil)
        if frame && !frame.empty?
          verbose { "Set [#{frame.inspect}]" }
          if length # Special for OSS
            @frame = frame.split(@terminator).map do|str|
              res = str.rjust(length.to_i, padding || '0')
              verbose(res.to_i > str.size) { "Frame length short and add '0'" }
              res
            end.join(@terminator)
          else
            @frame = frame
          end
        end
        self
      end

      # Cut frame and decode
      # If param includes 'val' key, it checks value  only
      # If cut str incldes terminetor, str will be trimmed
      def cut(e0)
        verbose { "Cut Start for [#{@frame.inspect}](#{@frame.size})" }
        return verify(e0) if e0['val'] # Verify value
        body, tm, rest = @terminator ? @frame.partition(@terminator) : [@frame]
        len = e0['length']
        del = e0['delimiter']
        if len
          verbose { "Cut by Size [#{len}]" }
          if len.to_i > body.size
            alert("Cut reached terminator [#{body.size}/#{len}] ")
            str = body
            @frame = rest.to_s
            cc_add(str)
          elsif len.to_i == body.size
            str = body
            @frame = [tm, rest].join
            verbose(tm) { 'Cut just end before terminator' }
            cc_add(str)
          else
            str = body.slice!(0, len.to_i)
            @frame = [body, tm, rest].join
            cc_add(str)
          end
        elsif del
          delimiter = eval('"' + del + '"')
          verbose { "Cut by Delimiter [#{delimiter.inspect}]" }
          str, dlm, body = body.partition(delimiter)
          verbose(tm && dlm) { "Cut by Terminator [#{@terminator.inspect}]" }
          @frame = [body, tm, rest].join
          cc_add([str, dlm].join)
        else
          verbose { 'Cut all the rest' }
          str = body
          @frame = rest.to_s
          cc_add([str, tm].join)
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
          str = str.slice(*r.split(':').map { |i| i.to_i })
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
        if  cc == @cc
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
          ref = eval(ref).to_s
        else
          val = str
        end
        if ref == val
          verbose { "Verify:(#{e0['label']}) [#{ref.inspect}] OK" }
        else
          alert("Mismatch(#{e0['label']}):[#{val.inspect}] (should be [#{ref.inspect}])")
        end
        cc_add(str)
        str
      end

      def decode(e, code) # Chr -> Num
        cdc = e['decode']
        return code.to_s unless cdc
        case cdc
        when 'hexstr' # "FF" -> "255"
          num = code.hex
          base = 16
        when 'decstr' # "80000123" -> "-123"
          # sign: k3n=F, oss=8,
          sign = (/[8Ff]/ === code[0]) ? '-' : ''
          num = sign + code[1..-1].sub(/0+/, '')
          base = 10
        when 'binstr'
          num = [code].pack('b*').ord
          base = 2
        else
          ary = code.unpack('C*')
          ary.reverse! if @endian == 'little'
          num = ary.inject(0) { |r, i| r * 256 + i }
          base = 256
        end
        case e['sign']
        when 'msb'
          range = base**code.size
          num = num < range / 2 ? num : num - range
        end
        verbose { "Decode:(#{cdc}) [#{code.inspect}] -> [#{num}]" }
        num.to_s
      end

      def encode(e, str) # Num -> Chr
        str = e['format'] % eval(str) if e['format']
        len = e['length']
        if len
          code = ''
          num = eval(str)
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
